package DTL::Fast::Filter::Last;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{last} = __PACKAGE__;

#@Override
sub filter
{
    my ( $self, $filter_manager, $value, $context ) = @_;

    if (ref $value eq 'ARRAY')
    {
        $value = $value->[- 1];
    }
    else
    {
        die $self->get_render_error(
                $context,
                sprintf(
                    "last filter may be applied only to an ARRAY reference, not %s (%s)"
                    , $value // 'undef'
                    , ref $value || 'SCALAR'
                )
            );
    }

    return $value;
}

1;