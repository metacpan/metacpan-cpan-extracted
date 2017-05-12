#!/usr/bin/perl -w

use strict;
use Test;
use Business::CINS;

BEGIN { plan tests => 26 }

my %bad_cds = map {$_ => 1} qw/I O Z/;

# Verify the domicile description list

for ('A'..'Z') {
  if (exists $bad_cds{$_}) {
    ok(!defined Business::CINS->domicile_descr($_));
  } else {
    ok(Business::CINS->domicile_descr($_));
  }
}
