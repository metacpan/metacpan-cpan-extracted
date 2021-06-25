#!perl

# Test B::CD records() method

use 5.010;
use strict;
use utf8;
use open qw(:std :utf8);
use Test::More;
use Test::Exception;
use Business::CompanyDesignator;
use Data::Dump qw(dd pp dump);

my ($bcd, @abbrev, @records, @long);

ok($bcd = Business::CompanyDesignator->new, 'constructor ok');

# Test searching via abbreviations
ok(@abbrev = $bcd->abbreviations, 'abbreviations method ok, found ' . scalar(@abbrev));
for my $abbrev (@abbrev) {
  ok(@records = $bcd->records($abbrev), "records found for abbrev '$abbrev': " . scalar(@records));
  for my $record (@records) {
    ok(ref $record && $record->isa('Business::CompanyDesignator::Record'),
      'record isa Business::CompanyDesignator::Record');
    my $long = $record->long;
    ok($long && ! ref $long, "long is string: " . $long);
    my @abbr = $record->abbr;
    ok(grep { $_ eq $abbrev } @abbr, "abbrev $abbrev included in '$long' abbreviations");
    if (my $abbr1 = $record->abbr1) {
      ok(! ref $abbr1, "abbr1 is string: " . $abbr1);
    }
    my $lang = $record->lang;
    ok($lang && ! ref $lang, "lang is string: " . $lang);
  }
}

# Test searching via longs
ok(@long = $bcd->long_designators, 'long_designators method ok, found ' . scalar(@long));
for my $long (@long) {
  ok(@records = $bcd->records($long), "records found for long '$long': " . scalar(@records));
  for my $record (@records) {
    ok(ref $record && $record->isa('Business::CompanyDesignator::Record'), 'record isa Business::CompanyDesignator::Record');
    is($record->long, $long, "\$record->long is '$long'");
    if (my @abbr = $record->abbr) {
      ok(@abbr, "abbr is array: " . join(',', @abbr));
    }
    if (my $abbr1 = $record->abbr1) {
      ok(! ref $abbr1, "abbr1 is string: " . $abbr1);
    }
    my $lang = $record->lang;
    ok($lang && ! ref $lang, "lang is string: " . $lang);
  }
}

dies_ok { $bcd->records('Bogus') } 'records() dies on bogus designator';

done_testing;

