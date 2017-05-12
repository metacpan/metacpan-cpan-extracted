package DTL::Fast::Expression::Operator::Binary::Div;
use strict; use utf8; use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Binary';

$DTL::Fast::OPS_HANDLERS{'/'} = __PACKAGE__;

use Scalar::Util qw(looks_like_number);

sub dispatch
{
    my( $self, $arg1, $arg2, $context) = @_;
    my ($arg1_type, $arg2_type) = (ref $arg1, ref $arg2);
    my $result = 0;

    if( looks_like_number($arg1) and looks_like_number($arg2))
    {
        $result = ($arg1 / $arg2);
    }
    elsif( UNIVERSAL::can($arg1, 'div'))
    {
        $result = $arg1->div($arg2);
    }
    else
    {
        die $self->get_render_error(
            $context,
            sprintf(
                "Don't know how to divide %s (%s) by %s (%s)"
                , $arg1 // 'undef'
                , $arg1_type || 'SCALAR'
                , $arg2 // 'undef'
                , $arg2_type || 'SCALAR'
            )
        );
    }

    return $result;
}

1;
