#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw(dies);

use Data::Transfigure qw(concat_position);

like(
  dies {concat_position()},
  qr/Too few arguments for subroutine 'Data::Transfigure::concat_position'/,
  'no arguments to concat_position'
);

is(concat_position(undef, undef), '/', 'concat undef with undef');
is(concat_position('',    undef), '/', 'concat empty with undef');
is(concat_position(undef, ''),    '/', 'concat undef with empty');

my $base;

is(concat_position($base, 'a'), "/a", 'concat undef with a');

$base = '';

is(concat_position($base, 'a'), "/a", 'concat empty with a');

$base = '/';

is(concat_position($base, 'a'), "/a", 'concat / with a');

$base = concat_position($base, 'a');

is(concat_position($base, 'b'), "/a/b", 'concat /a with b');

is(concat_position($base, "/b"), "/a/b", 'concat /a with /b');

is(concat_position("$base/", "b"), "/a/b", 'concat /a/ with b');

done_testing;
