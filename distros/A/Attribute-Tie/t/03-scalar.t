#
# $Id: 03-scalar.t,v 0.1 2006/12/22 22:47:49 dankogai Exp $
#
use strict;
use warnings;
use Attribute::Tie;
#use Test::More tests => 1;
use Test::More qw/no_plan/;
{
    package Tie::ConstantScalar;
    use base 'Tie::Scalar';
    sub TIESCALAR{ bless \eval{ my $scalar }, shift }
    sub FETCH{ 42 }
}

my $scalar : Tie('ConstantScalar');
ok tied($scalar), q{my $scalar : Tie('ConstantScalar')};
is $scalar, 42, q($scalar == ) . $scalar;
eval{
    $scalar = "Don't Panic";
};
ok $@, $@;

eval{
    my $noscalar : Tie('__NONE__');
};
ok $@, $@;
