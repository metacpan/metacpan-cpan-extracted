#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;

use Data::Collector;

# what happens when we want an engine that doesn't exist?
my $collector;

# engine is lazy
is(
    exception {
        $collector = Data::Collector->new( engine => 'J7fhZd90aZZ' );
    },
    undef,
    'Creating collector object',
);

isa_ok( $collector, 'Data::Collector' );

like(
    exception { $collector->engine_object },
    qr/^Can't load engine/,
    'Can\'t load engine',
);

