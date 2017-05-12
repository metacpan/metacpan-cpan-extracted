package DTL::Fast::Expression::Operator::Binary::Ne;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Expression::Operator::Binary::Eq';

$DTL::Fast::OPS_HANDLERS{'!='} = __PACKAGE__;
$DTL::Fast::OPS_HANDLERS{'<>'} = __PACKAGE__;

use Scalar::Util qw(looks_like_number);

sub render
{
    my $self = shift;
    return !$self->SUPER::render(@_);
}

1;