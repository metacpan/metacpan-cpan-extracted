#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 103;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;

my $am = "We're all living in America!";
my $s = BSON::String->new($am);
isa_ok( $s, 'BSON::String' );
is($s->value, $am, 'Value');
is("$s", $am, 'Overload');

for (1 .. 50) {
    my $i = int(rand(1_000_000));
    my $s = BSON::String->new($i);
    isa_ok( $s, 'BSON::String' );
    is("$s", "$i", "Number $i");
}

