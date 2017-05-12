use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests => 22}

use AccessorTest;

ok defined UNIVERSAL::can('AccessorTest', 'aa');
ok defined AccessorTest->can('aa');
ok ref(AccessorTest->can('aa')), 'CODE';

my $obj =AccessorTest->new;

ok defined $obj->can('aa');
ok ! defined $obj->can('ab');
ok defined $obj->can('bb');
ok ! defined $obj->aa;
$obj->aa(123);
ok defined $obj->aa;
ok $obj->aa, 123;

ok defined $obj->can('add_cc');
ok defined $obj->can('get_ccs');
ok defined $obj->can('remove_ccs');
ok $obj->get_ccs, undef;

foreach (qw(1 2 3 4)){ $obj->add_cc($_);}
ok scalar $obj->get_ccs, 4;
$obj->remove_ccs;
ok scalar $obj->get_ccs, 0;

ok defined $obj->can('add_ee');
ok defined $obj->can('get_ees');
ok defined $obj->can('remove_ees');

$obj->add_ee('1', 1234);
$obj->add_ee('2');
$obj->add_ee(undef);

my %hash=$obj->get_ees;
ok $hash{'1'}, 1234;
ok exists $hash{'2'};
ok ! defined $hash{'2'};
ok keys %hash, 3;


