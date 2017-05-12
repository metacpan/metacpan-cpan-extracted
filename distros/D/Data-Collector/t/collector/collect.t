#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;

use Sub::Override;
use Data::Collector;
use Data::Collector::Engine::OpenSSH;

my $sub = Sub::Override->new;

{
    package Data::Collector::Engine::MyTest;
    use Moose;
    extends 'Data::Collector::Engine';
    sub run {1}
}

{
    package Data::Collector::Info::EG;
    use Moose;
    extends 'Data::Collector::Info';
    sub info_keys { [] }
    sub all       { {} }
}

my $engine = Data::Collector::Engine::MyTest->new();
isa_ok( $engine, 'Data::Collector::Engine::MyTest' );

my $collector = Data::Collector->new(
    infos         => ['EG'],
    engine_object => $engine,
);

isa_ok( $collector, 'Data::Collector' );

is(
    exception { $collector->collect },
    undef,
    'Collecting once',
);

$engine->connected(1);

is(
    exception { $collector->collect },
    undef,
    'Collecting again',
);

# fake some engine to allow testing of loading
is(
    exception {
        $collector = Data::Collector->new(
            engine      => 'OpenSSH',
            engine_args => { host => 'heraldo' },
        );
    },
    undef,
    'New collector without problems',
);

is(
    exception { $collector->engine_object },
    undef,
    'Build engine successfully',
);
