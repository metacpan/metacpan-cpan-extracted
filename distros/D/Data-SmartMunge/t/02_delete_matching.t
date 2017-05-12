#!/usr/bin/env perl
use warnings;
use strict;
use Data::SmartMunge ':all';
use Test::More tests => 2;
use Test::Differences;

sub test_smart_munge {
    my ($data, $munger, $expect, $name) = @_;
    my $data_ref   = ref $data   || 'STRING';
    my $munger_ref = ref $munger || 'STRING';
    eq_or_diff scalar(smart_munge($data, $munger)),
      $expect, "$munger_ref($data_ref) $name";
}
test_smart_munge(
    'foo bar baz bar baz',
    delete_matching(qr/bar\s*/),
    'foo baz bar baz',
    'delete once'
);
test_smart_munge(
    'foo bar baz bar baz',
    delete_matching(qr/bar\s*/, 'g'),
    'foo baz baz', 'delete all'
);
