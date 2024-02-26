#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw(dies);

use Data::Transfigure::Value;
use Data::Transfigure::Constants;

use experimental qw(signatures);

my $v     = bless({}, 'MyClass');
my $v_ref = ref($v);
like(
  dies {
    Data::Transfigure::Value->new(value => $v, handler => sub { })
  },
  qr/^$v_ref is not acceptable for Data::Transfigure::Value\(value\)/,
  'check that value is of a supported type'
);

my $d = Data::Transfigure::Value->new(
  value   => 7,
  handler => sub ($entity) {
    $entity + 2;
  }
);

my $o = {
  a => 1,
  b => 7,
  c => 3,
  d => 'the cat jumped over the moon'
};

is($d->applies_to(value => $o),      $NO_MATCH,          'num value applies_to (hash)');
is($d->applies_to(value => $o->{a}), $NO_MATCH,          'num value applies_to (1)');
is($d->applies_to(value => $o->{b}), $MATCH_EXACT_VALUE, 'num value applies_to (7)');
is($d->applies_to(value => $o->{c}), $NO_MATCH,          'num value applies_to (3)');
is($d->applies_to(value => $o->{d}), $NO_MATCH,          'num value applies_to (str)');

is($d->transfigure($o->{b}), 9, 'num value transfigure');

$d = Data::Transfigure::Value->new(
  value   => qr/cat/,
  handler => sub ($entity) {
    $entity =~ s/cat/dog/gr;
  }
);

is($d->applies_to(value => $o),      $NO_MATCH,         'regex value applies_to (hash)');
is($d->applies_to(value => $o->{a}), $NO_MATCH,         'regex value applies_to (1)');
is($d->applies_to(value => $o->{b}), $NO_MATCH,         'regex value applies_to (7)');
is($d->applies_to(value => $o->{c}), $NO_MATCH,         'regex value applies_to (3)');
is($d->applies_to(value => $o->{d}), $MATCH_LIKE_VALUE, 'regex value applies_to (str)');

is($d->transfigure($o->{d}), 'the dog jumped over the moon', 'regex value transfigure');

$d = Data::Transfigure::Value->new(
  value   => sub ($v) {$v =~ /^-?\d+$/ && $v < 5},
  handler => sub ($entity) {
    -1;
  }
);

is($d->applies_to(value => $o),      $NO_MATCH,         'code value applies_to (hash)');
is($d->applies_to(value => $o->{a}), $MATCH_LIKE_VALUE, 'code value applies_to (1)');
is($d->applies_to(value => $o->{b}), $NO_MATCH,         'code value applies_to (7)');
is($d->applies_to(value => $o->{c}), $MATCH_LIKE_VALUE, 'code value applies_to (3)');
is($d->applies_to(value => $o->{d}), $NO_MATCH,         'code value applies_to (str)');

is($d->transfigure($o->{a}), -1, 'regex value transfigure (a)');
is($d->transfigure($o->{c}), -1, 'regex value transfigure (c)');

done_testing;
