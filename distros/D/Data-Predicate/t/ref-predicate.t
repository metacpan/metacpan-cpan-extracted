package main;

use strict;
use warnings;
use Test::More tests => 5;

use Data::Predicate::Predicates qw(:all);

my $p = p_ref_type('ARRAY');

my $str = 'str';
ok(! $p->apply(undef), 'Cannot call ref() on an undef value');
ok(! $p->apply($str), 'Cannot call ref() on a Scalar');
ok(! $p->apply(\$str), 'Wrong reftype on a ScalarRef');
ok(! $p->apply({}), 'Wrong reftype on a HashRef');
ok( $p->apply([]), 'Correct ref ArrayRef');
