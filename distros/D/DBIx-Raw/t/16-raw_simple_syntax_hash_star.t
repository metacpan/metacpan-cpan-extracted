#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 5;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $people = people();
my $db = prepare();
my $person  = $db->raw("SELECT * FROM dbix_raw WHERE id=1");

is(ref $person, 'HASH', 'Raw Hash Simple Syntax Star is Hash');

is($person->{id}, 1, 'Raw Hash Simple Syntax name');
is($person->{name}, $people->[0]->[0], 'Raw Hash Simple Syntax name');
is($person->{age}, $people->[0]->[1], 'Raw Hash Simple Syntax age');
