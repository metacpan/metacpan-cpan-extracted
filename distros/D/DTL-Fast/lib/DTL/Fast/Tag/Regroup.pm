package DTL::Fast::Tag::Regroup;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag::Simple';  

$DTL::Fast::TAG_HANDLERS{'regroup'} = __PACKAGE__;

use DTL::Fast::Variable;

#@Override
sub parse_parameters
{
    my $self = shift;

    if( $self->{'parameter'} =~ /^\s*(.+)\s+by\s+(.+?)\s+as\s+(.+?)\s*$/si )
    {
        @{$self}{qw( source grouper target_name)} = (
            DTL::Fast::Variable->new($1)
            , [(split /\./, $2)] # do we need to backup strings here ?
            , $3
        );
        
        die $self->get_parse_error("traget variable can't be traversable: $3") if $3 =~ /\./;
    }
    else
    {
        die $self->get_parse_error("do not understand condition: $self->{'parameter'}");
    }
    
    return $self;
}

#@Override
sub render
{
    my ($self, $context) = @_;

    my $source_array = $self->{'source'}->render($context);
    
    if( 
        defined $source_array
        and ref $source_array eq 'ARRAY' 
    )
    {
        my @groupers = ();
        my $groups = {};
    
        foreach my $source (@$source_array)
        {
            if( 
                defined $source
                and ref $source eq 'HASH' 
            )
            {
                my $grouper = $context->traverse($source, $self->{'grouper'}, $self);
                
                if( defined $grouper )
                {
                    if( not exists $groups->{$grouper} )
                    {
                        push @groupers, $grouper;
                        $groups->{$grouper} = [];
                    }
                    push @{$groups->{$grouper}}, $source;
                }
                else
                {
                    die $self->get_render_error(
                        $context,
                        "grouper value MUST exist and be defined in every source list item: ".join('.', @{$self->{'grouper'}})
                    );
                }
            }
        }
        
        my $grouped = [];
        
        foreach my $grouper (@groupers)
        {
            push @$grouped, {
                'grouper' => $grouper
                , 'list' => $groups->{$grouper}
            };
        }
        
        
        $context->set(
            $self->{'target_name'} => $grouped
        );
    }
    else
    {
        die $self->get_render_error(
            $context, 
            sprintf( "regroup can be applied to lists only: %s is a %s"
                , $self->{'source'}->{'original'} // 'undef'
                , ref $source_array
            )
        );
    }
    
    return '';
}


1;