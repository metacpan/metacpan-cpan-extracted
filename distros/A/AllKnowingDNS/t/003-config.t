#!perl
# vim:ts=4:sw=4:expandtab
#
# Verify that the App::AllKnowingDNS::Config object works.

use Test::More;
use Data::Dumper;
use strict;
use warnings;
use lib qw(lib);

use_ok('App::AllKnowingDNS::Config');

my $config = App::AllKnowingDNS::Config->new;
isa_ok($config, 'App::AllKnowingDNS::Config');

ok(!defined($config->zone_for_ptr('0.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa')),
   'empty config does not handle our PTR zone');
ok(!defined($config->zone_for_aaaa('.nutzer.raumzeitlabor.de')),
   'empty config does not handle our AAAA zone');

my $zone = App::AllKnowingDNS::Zone->new;
$zone->network('2001:4d88:100e:ccc0::/64');
$zone->resolves_to('ipv6-%DIGITS%-blah.nutzer.raumzeitlabor.de');
$config->add_zone($zone);

ok(defined($config->zone_for_ptr('7.c.e.2.3.4.e.f.f.f.b.d.9.1.2.0.0.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa')),
   'network properly handled');
ok(!defined($config->zone_for_ptr('7.c.e.2.3.4.e.f.f.f.b.d.9.1.2.0.1.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa')),
   'different network not handled');

ok(defined($config->zone_for_aaaa('ipv6-a-blah.nutzer.raumzeitlabor.de')),
   'network properly handled');
ok(!defined($config->zone_for_aaaa('ipv6-b-blah.servers.raumzeitlabor.de')),
   'different network not handled');

done_testing;
