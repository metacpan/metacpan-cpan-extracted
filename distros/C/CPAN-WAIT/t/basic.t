#!perl
#                              -*- Mode: Perl -*- 
# test.pl -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Jan 31 16:34:58 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu Mar 23 18:09:53 2000
# Language        : CPerl
# Update Count    : 31
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Universität Dortmund, all rights reserved.
# 
my $skip;
BEGIN {
  $| = 1;
  if (-f '.notest') {
    $skip = "# skipped by user request!";
  } else {
    $skip = '';
  }
  print "1..5\n";
}
END {print "not ok 1\n" unless $loaded;}
use CPAN::WAIT;
$loaded = 1;
print "ok 1\n";
my $test   = 2;

my
$status = CPAN::WAIT->wh() unless $skip;
print "not " unless $skip or $status; print "ok $test $skip\n"; $test++;

$status = CPAN::WAIT->wl(3) unless $skip;
print "not " unless $skip or $status; print "ok $test $skip\n"; $test++;

$status = CPAN::WAIT->wq(qw(au=wall and au=larry)) unless $skip;
print "not " unless $skip or $status; print "ok $test $skip\n"; $test++;

$status = CPAN::WAIT->wr(1) unless $skip;
print "not " unless $skip or $status; print "ok $test $skip\n"; $test++;

