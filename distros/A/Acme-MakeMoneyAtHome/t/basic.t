use Test::More;
use strict; use warnings FATAL => 'all';

use Acme::MakeMoneyAtHome;

my $str = make_money_at_home;
ok length $str, "function produced some crap";
note $str;

done_testing
