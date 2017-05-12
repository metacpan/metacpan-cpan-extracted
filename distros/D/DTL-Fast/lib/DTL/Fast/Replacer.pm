package DTL::Fast::Replacer;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Entity';

use DTL::Fast::Replacer::Replacement;
use DTL::Fast::Variable;

our $VERSION = '1.00';

sub backup_strings
{
    my( $self, $expression ) = @_;

    $self->clean_replacement($expression)
        if not $self->{'replacement'}
            or not $self->{'replacement'}->isa('DTL::Fast::Replacer::Replacement');
    
    $expression =~ s/(?<!\\)(["'])(.*?)(?<!\\)\1/$self->backup_value($1.$2.$1)/ge;
    
    return $expression;
}

sub backup_value
{
    my( $self, $value ) = @_;

    return $self->{'replacement'}->add_replacement(
        DTL::Fast::Variable->new($value)
    );
}

sub backup_expression
{
    my( $self, $expression ) = @_;

    return $self->{'replacement'}->add_replacement(
        DTL::Fast::Expression->new(
            $expression
            , 'replacement' => $self->{'replacement'}
            , 'level' => 0 
        )
    );
}

sub get_backup
{
    return shift->{'replacement'}->get_replacement(shift);
}


sub get_backup_or_variable
{
    my( $self, $token ) = @_;

    my $result = $self->get_backup($token) 
        // DTL::Fast::Variable->new( $token, 'replacement' => $self->{'replacement'} );
        
    return $result;
}

sub get_backup_or_expression
{
    my( $self, $token, $current_level ) = @_;
    $current_level //= -1;

    my $result = $self->get_backup($token)
        // DTL::Fast::Expression->new(
            $token
            , 'replacement' => $self->{'replacement'}
            , 'level' => $current_level+1 
        );
   
    return $result;
}

sub clean_replacement
{
    return shift->set_replacement(
        DTL::Fast::Replacer::Replacement->new(shift)
    );
}

sub set_replacement
{
    my( $self, $replacement ) = @_;
    $self->{'replacement'} = $replacement;
    return $self;
}

sub parse_sources
{
    my( $self, $source ) = @_;
    
    my $sources = $self->backup_strings($source);

    warn $self->get_parse_warning(
        sprintf(
            "comma-separated source values in %s tag are DEPRICATED, please use spaces:\n\t%s"
            , ref $self
            , $source
        )
    ) if $sources =~ /,/;
        
    my $result = [];
    
    foreach my $source (split /[,\s]+/, $sources)
    {
        if( $source =~ /^(__BLOCK_.+?)\|(.+)$/ )   # filtered static variable
        {
            push @$result, $self->get_backup_or_variable($1);
            $result->[-1]->{'filter_manager'}->parse_filters($2);
        }
        else
        {
            push @$result, $self->get_backup_or_variable($source) 
        }
    }

    return $result;
}

1;