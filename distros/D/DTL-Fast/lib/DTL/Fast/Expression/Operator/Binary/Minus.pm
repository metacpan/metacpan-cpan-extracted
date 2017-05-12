package DTL::Fast::Expression::Operator::Binary::Minus;
use strict; use utf8; use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Binary';

$DTL::Fast::OPS_HANDLERS{'-'} = __PACKAGE__;

use Scalar::Util qw(looks_like_number);

sub dispatch
{
    my( $self, $arg1, $arg2, $context) = @_;
    my ($arg1_type, $arg2_type) = (ref $arg1, ref $arg2);

    if( looks_like_number($arg1) and looks_like_number($arg2))
    {
        return $arg1 - $arg2;
    }
    elsif( $arg1_type eq 'ARRAY' ) # @todo array substitution
    {
        die $self->get_render_error( $context, 'arrays substitution not yet implemented');
    }
    elsif( $arg1_type eq 'HASH' )   # @todo hash substitution
    {
        die $self->get_render_error( $context, 'hashes substitution not yet implemented');
    }
    elsif( UNIVERSAL::can($arg1, 'minus'))
    {
        return $arg1->minus($arg2);
    }
    else
    {
        die $self->get_render_error(
            $context,
            sprintf("don't know how to substitute %s (%s) from %s (%s)"
                , $arg1 // 'undef'
                , $arg1_type || 'SCALAR'
                , $arg2 // 'undef'
                , $arg2_type || 'SCALAR'
            )
        );
    }
}

1;
