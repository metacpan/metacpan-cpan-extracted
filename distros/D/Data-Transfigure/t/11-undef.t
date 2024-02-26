#!/usr/bin/perl
use v5.26;
use warnings;
use experimental qw(signatures);

use Test2::V0;

use Data::Transfigure::Value;
use Data::Transfigure::Constants;

my $d = Data::Transfigure::Value->new(
  value   => undef,
  handler => sub ($entity) {
    return "__UNDEF__";
  }
);

my $o = {
  a => 1,
  b => undef,
  c => "3",
};

is($d->applies_to(value => $o),      $NO_MATCH,          'check undef applies_to (hash)');
is($d->applies_to(value => $o->{a}), $NO_MATCH,          'check undef applies_to (num)');
is($d->applies_to(value => $o->{b}), $MATCH_EXACT_VALUE, 'check undef applies_to (undef)');
is($d->applies_to(value => $o->{c}), $NO_MATCH,          'check undef applies_to (str)');

is($d->transfigure($o),      '__UNDEF__', 'transfigure undef (hash)');
is($d->transfigure($o->{a}), '__UNDEF__', 'transfigure undef (num)');
is($d->transfigure($o->{b}), '__UNDEF__', 'transfigure undef (undef)');
is($d->transfigure($o->{c}), '__UNDEF__', 'transfigure undef (str)');

done_testing;
