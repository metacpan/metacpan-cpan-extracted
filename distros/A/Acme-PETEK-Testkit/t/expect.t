#!/usr/bin/perl -w

use strict;
use Test::Expect;
use Test::More tests => 6;

expect_run(
  command => "perl -Ilib scripts/lc.pl",
  prompt  => "> ",
  quit    => ".",
);

expect_send("t","Sent pattern of 't'");
expect_send("t","Sent a 't'");
expect_send("u","Sent a 'u'");
expect_send("?","Asked for current matches");
expect_like(qr/Matches: 1/,"Expecting one match");
