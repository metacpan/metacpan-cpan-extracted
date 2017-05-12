#!perl

package main;
use strict;
use warnings;

use Test::More tests => 4;

use Data::Collector::Engine;

my $run;
my $engine = Data::Collector::Engine->new;

isa_ok( $engine, 'Data::Collector::Engine' );

eval { $engine->run };
$@ =~ /^No default run method at/ and $run++;

ok( $run, 'Default engine run() dies' );

cmp_ok( $engine->connect,    '==', 1, 'Default connect'    );
cmp_ok( $engine->disconnect, '==', 1, 'Default disconnect' );

