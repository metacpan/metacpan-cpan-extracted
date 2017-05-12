package DTL::Fast::Filter::Unorderedlist;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'unordered_list'} = __PACKAGE__;

#@Override
sub filter
{
    my($self, $filter_manager, $value, $context ) = @_;
    
    die $self->get_render_error(
        $context, 
        sprintf(
            "Argument must be an ARRAY reference, not %s (%s)"
            , $value // 'undef'
            , ref $value || 'SCALAR'
        )
    ) if ref $value ne 'ARRAY';
    
    $self->{'global_safe'} = $context->{'ns'}->[-1]->{'_dtl_safe'};
    $self->{'safeseq'} = $filter_manager->{'safeseq'};
    $filter_manager->{'safe'} = 1;
    
    return $self->make_list($value, {});
}

sub make_list
{
    my $self = shift;
    my $array = shift;
    my $recursion_control = shift;
    
    warn "Recursive data encountered, skipping" and return if exists $recursion_control->{$array};
    
    $recursion_control->{$array} = 1;
    my @values = ();
    
    foreach my $element (@$array)
    {
        my $element_type = ref $element;
        if( $element_type eq 'ARRAY' )
        {
            my $rendered = $self->make_list($element, $recursion_control);

            if( $rendered )
            {
                $rendered =~ s/^/\t/mg;
                push @values, sprintf( "\t<ul>\n%s\t</ul>\n", $rendered  // 'undef');
            }

        }
        else
        {
            push @values, sprintf(
                "\t<li>%s</li>"
                , ( not $self->{'safeseq'} and not $self->{'global_safe'} )
                    ? DTL::Fast::html_protect($element // '')
                    : $element // ''
            )."\n";
        }
    }
    
    delete $recursion_control->{$array};
    return join '', @values;
}

1;