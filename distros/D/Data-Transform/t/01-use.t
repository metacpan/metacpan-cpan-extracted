#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

BEGIN { use_ok("Data::Transform") }

eval { my $x = Data::Transform->new() };
ok(
  $@ && $@ =~ /not meant to be used directly/,
  "don't instantiate Data::Transform"
);

exit 0;
