#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

my $temp_root = $ENV{TEMP} || $ENV{TMP} || '/tmp';
my $filename = "$temp_root/db_asp4";
ok( unlink($filename), "unlink('$filename')" );
map {
  ok(
    unlink($_),
    "unlink('$_')"
  );
} <$temp_root/PAGE_CACHE/DefaultApp/*.pm>;


