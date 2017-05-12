# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# test 1
BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::OnlinePayment::MerchantCommerce;
$loaded = 1;
print "ok 1\n";
