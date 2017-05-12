package DTL::Fast::Filter::Reverse;
use strict; use utf8; use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'reverse'} = __PACKAGE__;

#@Overrde
sub filter
{
    my( $self, $filter_manager, $value, $context ) = @_;
    my $result;

    my $value_type = ref $value;

    if( $value_type eq 'ARRAY' )
    {
        $result = [reverse @$value];
    }
    elsif( $value_type eq 'HASH' )
    {
        $result = {reverse %$value};
    }
    elsif( UNIVERSAL::can($value_type, 'reverse') )
    {
        $result = $value->reverse($context);
    }
    elsif( not $value_type )
    {
        $result = join '', reverse ($value =~ /(.)/gs);
    }
    else
    {
        die $self->get_render_error( $context, "don't know how to reverse $value ($value_type)");
    }

    return $result;
}

1;
