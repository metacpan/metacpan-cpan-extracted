#!perl -T

use strict;
use warnings;

use lib q(lib);

use Test::More tests => 6;
use Data::AsObject qw(dao);

my $dao = dao { foo => 42, hello => { world => 1 } };
my $ref;

ok($ref = $dao->can('foo'), 'dao can "foo"');
is(ref $ref, 'CODE', 'can() returns a code ref');
is($ref->(), 42, 'code ref returns data value');
ok($ref = $dao->can('hello'), 'dao can "hello"');
is($dao->$ref->world, 1, 'sub ref holds object');
is($dao->can('bar'), undef, 'can "bar" returns undef value');
