#!/usr/bin/perl

use 5.018;
use strict;
use warnings;
use Test::More tests => 4;

use App::PTP::Args;
use List::Util qw(none all);

sub uniqstr (@) {
  my (@l) = @_;
  for my $i (0 .. $#l - 1) {
    undef $l[$i] if $l[$i] eq $l[$i+1];
  }
  return grep { defined } @l;
}


my %cmd_args = App::PTP::Args::all_args();
my @args = sort map { split /\|/, s/[:=!+].*//r } keys %cmd_args;

my @uniq_args = uniqstr @args;
ok(@args == @uniq_args, "All arguments are unique.");

ok((none { /^-/ } @args), "No arguments start with a dash.");

ok((none { /[^-a-zA-Z]/ } grep { not /^(<>|0|00)$/ } @args),
   "Arguments contains only letters and dashes.");

ok((all { (not /[A-Z]/) or length == 1 } @args),
    "Only one letter arguments are in capital letters.");
