use strict;
use Test::More;

use Acme::YAPC::Okinawa::Bus;

is(Acme::YAPC::Okinawa::Bus::time(), '朝7時45分');
is(Acme::YAPC::Okinawa::Bus::place(), '県庁前');

done_testing;

