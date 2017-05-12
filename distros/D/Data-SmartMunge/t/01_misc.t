#!/usr/bin/env perl
use warnings;
use strict;
use Data::SmartMunge qw(smart_munge);
use Test::More tests => 7;
use Test::Differences;

sub test_smart_munge {
    my ($data, $munger, $expect, $name) = @_;
    my $data_ref   = ref $data   || 'STRING';
    my $munger_ref = ref $munger || 'STRING';
    eq_or_diff scalar(smart_munge($data, $munger)),
      $expect, "$munger_ref($data_ref) $name";
}
test_smart_munge('foo bar baz', sub { uc $_[0] }, 'FOO BAR BAZ', 'uppercase');
test_smart_munge('foo bar baz', undef, 'foo bar baz', 'undefined munger');
test_smart_munge(
    [ 1 .. 4 ],
    sub { [ reverse @{ $_[0] } ] },
    [ 4, 3, 2, 1 ], 'reverse'
);
test_smart_munge(
    [ 1 .. 4 ],
    undef,
    [ 1 .. 4 ], 'undefined munger'
);
test_smart_munge(
    { a => 'foo', b => 'bar' },
    sub {
        +{ map { $_ => uc $_[0]->{$_} } keys %{ $_[0] } };
    },
    { a => 'FOO', b => 'BAR' },
    'uppercase values'
);
test_smart_munge(
    { a => 'foo', b => 'bar' },
    undef,
    { a => 'foo', b => 'bar' },
    'undefined munger'
);
test_smart_munge(
    { a => 'foo', b => 'bar' },
    { a => undef, c => 'baz' },
    { a => undef, b => 'bar', c => 'baz' },
    'overlay'
);
