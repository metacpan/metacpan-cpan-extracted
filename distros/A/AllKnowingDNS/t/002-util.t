#!perl
# vim:ts=4:sw=4:expandtab
#
# Verify that the App::AllKnowingDNS::Util functions work.

use Test::More;
use Data::Dumper;
use strict;
use warnings;
use lib qw(lib);

use_ok('App::AllKnowingDNS::Util');

my $ptrzone = netmask_to_ptrzone('2001:4d88:100e:ccc0::/64');
is($ptrzone, '0.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa',
   '2001:4d88:100e:ccc0::/64 correctly converted to PTR zone');

$ptrzone = netmask_to_ptrzone('2001:4d88:100e:ccc0::/48');
is($ptrzone, 'e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa',
   '2001:4d88:100e:ccc0::/48 correctly converted to PTR zone');

$ptrzone = netmask_to_ptrzone('2001:4d88:100e:ccc0::/80');
is($ptrzone, '0.0.0.0.0.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa',
   '2001:4d88:100e:ccc0::/80 correctly converted to PTR zone');

done_testing;
