package DTL::Fast::Expression::Operator::Binary::And;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Binary::Logical';

$DTL::Fast::OPS_HANDLERS{and} = __PACKAGE__;

sub dispatch
{
    my ( $self, $arg1, $context ) = @_;

    if (UNIVERSAL::can($arg1, 'and'))
    {
        return $arg1->and($self->get_b($context));
    }
    else
    {
        return $arg1 && $self->get_b($context);
    }
}

1;
