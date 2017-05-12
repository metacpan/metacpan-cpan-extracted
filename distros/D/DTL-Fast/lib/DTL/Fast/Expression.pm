package DTL::Fast::Expression;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Replacer';

use DTL::Fast;
use DTL::Fast::Variable;
use DTL::Fast::Expression::Operator;
use DTL::Fast::Replacer::Replacement;

use Data::Dumper;

our %EXPRESSION_CACHE = ();
our $EXPRESSION_CACHE_HITS = 0;

# @todo cache mechanism via get_expression
sub new
{
    my( $proto, $expression, %kwargs ) = @_;
    my $result = undef;

    $expression =~ s/^\s+|\s+$//xgsi;
    
    if( 
        not $kwargs{'replacement'}          # cache only top-level expressions
        and not $kwargs{'level'}            # same ^^
        and $EXPRESSION_CACHE{$expression}  # has cached expression
    )
    {
        $result = $EXPRESSION_CACHE{$expression};
        $EXPRESSION_CACHE_HITS++;
    }
    else
    {
        $kwargs{'expression'} = $expression;
        $kwargs{'level'} //= 0;        
            
        my $self = $proto->SUPER::new(%kwargs);

        $self->{'expression'} = $self->_parse_expression(
            $self->_parse_brackets(
                $self->backup_strings($expression)
            )
        );

        $EXPRESSION_CACHE{$expression} = $result = $self->{'expression'};
    }
   
    return $result;
}

sub _parse_brackets
{
    my( $self, $expression ) = @_;

    $expression =~ s/\s+/ /xgsi;
    while( $expression =~ s/
            \(\s*([^()]+)\s*\)
        /
            $self->backup_expression($1)
        /xge ){};
    
    die $self->get_parse_error('unpaired brackets in expression')
        if $expression =~ /[()]/;
    
    return $expression;
}

sub get_parse_error
{
    my ($self, $message, @additional) = @_;
    
    return $self->SUPER::get_parse_error(
        $message
        , @additional
        , 'Expression' => $self->{'expression'}
    );
}

sub _parse_expression
{
    my( $self, $expression ) = @_;
    
    my $result = undef;
    
    for( my $level = $self->{'level'}; $level < scalar @DTL::Fast::OPS_RE; $level++ )
    {
        my $operators = $DTL::Fast::OPS_RE[$level];
        my @result = ();
        my @source = split /
                (?:^|\s+)
                    ($operators)
                (?:$|\s+)
            /six, $expression;

        if( scalar @source > 1 ) 
        {
            # processing operands
            while( defined ( my $token = shift @source) )
            {
                next if $token eq ''; 
                
                if( $token =~ /^$operators$/six ) # operation
                {
                    push @result, $token;
                }
                else 
                {
                    push @result, $self->get_backup_or_expression($token, $level);
                }
            }
            
            # processing operators
            while( my $token  = shift @result )
            {
                if( ref $token ) # operand
                {
                    $result = $token;
                }
                else    # operator
                {
                    if( 
                        scalar @result      # there is a next token
                        and ref $result[0]  # it's an operand
                    )
                    {
                        my $operand = shift @result;
                        
                        if( not exists $DTL::Fast::OPS_HANDLERS{$token}
                            and exists $DTL::Fast::KNOWN_OPS_PLAIN{$token}
                        )
                        {
                            require Module::Load;
                            Module::Load::load($DTL::Fast::KNOWN_OPS_PLAIN{$token});
                            $DTL::Fast::LOADED_MODULES{$DTL::Fast::KNOWN_OPS_PLAIN{$token}} = time;            
                            $DTL::Fast::OPS_HANDLERS{$token} = $DTL::Fast::KNOWN_OPS_PLAIN{$token};
                        }
                        
                        my $handler = $DTL::Fast::OPS_HANDLERS{$token} || die $self->get_parse_error("there is no processor for $token operator");
                        
                        if($handler->isa('DTL::Fast::Expression::Operator::Binary'))
                        {
                            if( defined $result )
                            {
                                $result = $handler->new( $result, $operand );
                            }
                            else
                            {
                                die $self->get_parse_error(
                                    sprintf('binary operator `%s` has no left argument'
                                        , $token // 'undef'
                                    )
                                );
                            }
                        }
                        elsif( $handler->isa('DTL::Fast::Expression::Operator::Unary') )
                        {
                            if( defined $result )
                            {
                                die $self->get_parse_error(
                                    sprintf('unary operator `%s` got left argument'
                                        , $token // 'undef'
                                    )
                                );
                            }
                            else
                            {
                                $result = $handler->new( $operand);
                            }
                        }
                        else
                        {
                            die $self->get_parse_error('Unknown operator handler: '.$handler);
                        }
                    }
                    else # got operator but there is no more operands
                    {
                        die $self->get_parse_error(
                            sprintf('operator `%s` has no right argument'
                                , $token // 'undef'
                            )
                        );
                    }
                }
            }
            last if $result;    # parsed level
        }
            
    }
    return 
        $result 
        // $self->get_backup_or_variable($expression)
        ;
}

1;