#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use Business::ReportWriter::OOCalc;

  my $s = new Business::ReportWriter::OOCalc();
  ok(defined $s);
  ok($s->isa('Business::ReportWriter::OOCalc'));
