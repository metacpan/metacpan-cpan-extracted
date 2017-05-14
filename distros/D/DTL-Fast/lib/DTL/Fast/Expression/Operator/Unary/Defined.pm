package DTL::Fast::Expression::Operator::Unary::Defined;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Unary';

$DTL::Fast::OPS_HANDLERS{defined} = __PACKAGE__;

sub render
{
    my ( $self, $context) = @_;
    my $result = undef;

    if ($self->{a}->{undef})
    {
        $result = 1;
    }
    else
    {
        $result = defined $self->{a}->render($context, 1);
    }

    return $result;
}

1;