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
my $person = $db->raw("SELECT * fROM dbix_raw WHERE id=229");
is($person, undef, 'Raw Undef Simple Syntax');
