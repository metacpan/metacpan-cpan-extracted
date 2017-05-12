#!perl

use strict;
use warnings;

use Test::Deep;
use Test::More tests => 3;

require_ok('AtomicParsley::Command::Tags');

my $tags = new_ok(
    'AtomicParsley::Command::Tags',
    [
        artist => 'foo',
        title  => 'bar',
        album  => '',

        #        genre   => {},
        #        disk    => [],
        #        comment => (),
        comment => undef,
    ]
);

my @p = $tags->prepare;
cmp_bag( \@p, [ '--artist', 'foo', '--title', 'bar', '--album', '' ] );