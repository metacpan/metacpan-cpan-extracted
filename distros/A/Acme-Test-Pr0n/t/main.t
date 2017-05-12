#!/usr/bin/perl -w

use strict;

use lib qw( ./blib/lib ../blib/lib );

  use Test::More tests => 3;
  use Acme::Test::Pr0n;

  my $filename = 't/test.data';

  my $pr0n_test = Acme::Test::Pr0n->new({
      'filename' => $filename,
  });

  ok($pr0n_test->pr0n() > 1,
             'The string pr0n is hidden in the file more than 1 time');

  ok($pr0n_test->XXX() == 1,
             'The string XXX is hidden in the file once');

  ok($pr0n_test->XXX('i') == 3,
             'XXX hidden in the file 3 times, case sensative');
