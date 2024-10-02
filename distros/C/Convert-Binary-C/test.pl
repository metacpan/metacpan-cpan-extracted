#!/usr/bin/perl -w
################################################################################
#
# Copyright (c) 2005-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

BEGIN {
  $only_basic = $] < 5.005;

  if ($only_basic) {
    print STDERR <<ENDWARN;

--> WARNING: The version of perl you're using ($]) is very old.
-->
-->   The complete test suite cannot be run with perl < 5.005.
-->
-->   I will only run some very basic tests now.

ENDWARN
  }

  eval q{
    use Test::Harness;
    $Test::Harness::switches = "-w";
  };
}

@tests = @ARGV ? @ARGV : find_tests();
die "*** Can't find any test files\n" unless @tests;

$ENV{PERL_DL_NONLAZY} = 1;

runtests(@tests);

sub find_tests
{
  use File::Find;
  my $fd = $only_basic ? '1' : $ENV{ONLY_FAST_TESTS} ? '[0123478]' : '\d';
  my %t;
  find(sub { -f and /^$fd\d{2}_\w+\.t$/ and $t{$File::Find::name}++ }, 'tests');
  return sort keys %t;
}
