#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

{
    package ArtifactList;
    use Moose;

    has stuff => (
        is          => 'rw',
    );

    sub such_that { }

    with 'Bolts::Role::Artifact';

    sub get { shift->stuff }
}

{
    package AllTest;
    use Bolts;

    artifact array => (
        builder => sub { [ 1, 2, 3 ] },
    );

    artifact hash => (
        builder => sub { { 'foo' => 'zip', 'bar' => 'zap', 'baz' => 'zop' } },
    );

    artifact scalar => (
        builder => sub { 42 },
    );

    artifact artifact_list => ArtifactList->new(
        stuff => [ qw( a b c ) ],
    );

    artifact artifact_hash => ArtifactList->new(
        stuff => { abc => 123, def => 456, ghi => 789 },
    );

    artifact artifact_scalar => ArtifactList->new(
        stuff => 'blah',
    );
}

my $bag = AllTest->new;

is_deeply($bag->acquire_all('array'), [ 1, 2, 3 ]);
is_deeply([ sort @{ $bag->acquire_all('hash') } ], [ 'zap', 'zip', 'zop' ]);
is_deeply($bag->acquire_all('scalar'), [ 42 ]);
is_deeply($bag->acquire_all('artifact_list'), [ 'a', 'b', 'c' ]);
is_deeply([ sort @{ $bag->acquire_all('artifact_hash') } ], [ 123, 456, 789 ]);
is_deeply($bag->acquire_all('artifact_scalar'), [ 'blah' ]);
