#!/usr/bin/env perl

# test-showtable.t

unshift(@INC,'../blib/lib') if -d '../blib/lib';
unshift(@INC,'t') if -d 't';

use Data::ShowTable;
require 'Test-Setup.pl';

sub start_tests($);
sub run_test($&);

$script = '';
foreach $dir ('blib', '../blib') {
  if (-d $dir && -f "$dir/script/showtable") {
    $script = "$dir/script";
    last;
  }
}

if ($script eq '') {
  die "Cannot find path to local 'showtable'\n";
}

$testdir = '';
foreach $dir ('t', '../t') {
  if (-d $dir && -f "$dir/testdates.txt") {
    $testdir = "$dir";
    last;
  }
}

if ($testdir eq '') {
  die "Cannot find path to test directory.\n";
}

start_tests 1;

# Test negative widths
run_test 1, sub {
    system("$script/showtable -d' ' $testdir/testdates.txt");
  };

