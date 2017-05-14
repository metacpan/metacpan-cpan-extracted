package DTL::Fast::Expression::Operator::Unary::Logical;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Unary';

use DTL::Fast::Utils qw(as_bool);

sub render
{
    my ( $self, $context ) = @_;

    return $self->dispatch(
        as_bool($self->{a}->render($context, 1))
        , $context
    );
}

1;