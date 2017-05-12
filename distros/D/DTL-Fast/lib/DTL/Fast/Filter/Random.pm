package DTL::Fast::Filter::Random;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'random'} = __PACKAGE__;

#@Override
sub filter
{
    my( $self, $filter_manager, $value, $context ) = @_;
    
    die $self->get_render_error(
        $context,
        sprintf("Argument must be an ARRAY ref, not %s (%s)"
            , $value // 'undef'
            , ref $value || 'SCALAR'
        )
    ) if ref $value ne 'ARRAY';

    return $value->[int(rand scalar @$value)];
}

1;