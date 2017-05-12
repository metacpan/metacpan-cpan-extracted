#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok("Business::OnlinePayment")
      or BAIL_OUT("unable to load Business::OnlinePayment\n");
}
