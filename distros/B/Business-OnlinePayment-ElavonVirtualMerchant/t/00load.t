#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok("Business::OnlinePayment")
      or BAIL_OUT("unable to load Business::OnlinePayment\n");

    use_ok("Business::OnlinePayment::ElavonVirtualMerchant")
      or BAIL_OUT("unable to load Business::OnlinePayment::ElavonVirtualMerchant\n");
}
