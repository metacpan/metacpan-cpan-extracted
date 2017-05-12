#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 3;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $people = people();
my $db = prepare();
my ($name, $age) = $db->raw(query=>"SELECT name,age FROM dbix_raw WHERE id=?", vals => [1]);

is($name, $people->[0]->[0], 'Raw List Complex Syntax name with vals');
is($age, $people->[0]->[1], 'Raw List Complex Syntax vals age with vals');
