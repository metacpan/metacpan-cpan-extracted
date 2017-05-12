package DTL::Fast::Expression::Operator::Binary::NotIn;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Expression::Operator::Binary::In';

$DTL::Fast::OPS_HANDLERS{'not in'} = __PACKAGE__;

sub render
{
    my $self = shift;
    return !$self->SUPER::render(@_);
}

1;