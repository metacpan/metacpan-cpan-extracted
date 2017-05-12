# vim:set syntax=perl:

use Test::More tests => 2;

BEGIN { use_ok('Business::OnlinePayment') };
BEGIN { use_ok('Business::OnlinePayment::InternetSecure') };
