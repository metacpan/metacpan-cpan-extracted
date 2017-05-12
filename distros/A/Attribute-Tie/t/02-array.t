#
# $Id: 02-array.t,v 0.2 2009/02/08 09:00:27 dankogai Exp dankogai $
#
use strict;
use warnings;
use Attribute::Tie;
#use Test::More tests => 1;
use Test::More qw/no_plan/;
{
    package Tie::EchoArray;
    use base 'Tie::Array';
    sub TIEARRAY{ bless [], shift; }
    sub FETCH{ $_[1] }
    sub FETCHSIZE{ 0x7fffffff };
}

my @array : Tie('EchoArray');
ok tied(@array), q{my @array : Tie('EchoArray')};
is $array[42], 42, q($array[42] == ) . $array[42];
eval{
    $array[42] = "Don't Panic!";
};
ok $@, $@;

eval{
    my %noarray : Tie('__NONE__');
};
ok $@, $@;
eval{
    my @file : Tie('File', './_none_/db');
};
ok $@, $@;

