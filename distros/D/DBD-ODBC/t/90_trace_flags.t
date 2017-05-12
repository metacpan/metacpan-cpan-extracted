#!/usr/bin/perl -w -I./t
use 5.006;
use strict;
use warnings;
use Test::More;
use DBI;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}

my $h = DBI->connect();
unless($h) {
   BAIL_OUT("Unable to connect to the database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}

my $bit;
$bit = $h->parse_trace_flag('odbcunicode');
is($bit, 0x02_00_00_00, 'odbcunicode');

$bit = $h->parse_trace_flag('odbcconnection');
is($bit, 0x04_00_00_00, 'odbcconnection');

my $val;
$val = $h->parse_trace_flags('odbcunicode|odbcconnection');
is($val, 0x06_00_00_00, "parse_trace_flags");

$h->disconnect;

Test::NoWarnings::had_no_warnings()
  if ($has_test_nowarnings);

done_testing;
