#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 2;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $people = people();
my $db = prepare();
is($db->raw(query=>"SELECT name FROM dbix_raw WHERE id=1"), $people->[0]->[0], 'Raw Scalar Complex Syntax');
