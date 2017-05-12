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
        $collector = Data::Collector->new( format => 'J7fhZd90aZZ' );
    },
    undef,
    'Creating collector object',
);

isa_ok( $collector, 'Data::Collector' );

like(
    exception { $collector->serialize },
    qr/^Can't load serializer/,
    'Can\'t load serializer',
);

