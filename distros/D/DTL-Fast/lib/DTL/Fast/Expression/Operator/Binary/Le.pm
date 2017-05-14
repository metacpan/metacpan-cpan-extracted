package DTL::Fast::Expression::Operator::Binary::Le;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Binary::Ge';

$DTL::Fast::OPS_HANDLERS{'<='} = __PACKAGE__;

sub dispatch
{
    my ( $self, $arg1, $arg2, $context) = @_;

    return $self->SUPER::dispatch($arg2, $arg1, $context);
}

1;