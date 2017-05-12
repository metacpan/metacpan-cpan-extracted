#!perl
# vim:ts=4:sw=4:expandtab
#
# Verify that the App::AllKnowingDNS::Handler works.

use Test::More;
use Data::Dumper;
use strict;
use warnings;
use lib qw(lib);

use_ok('App::AllKnowingDNS::Config');
use_ok('App::AllKnowingDNS::Zone');
use_ok('App::AllKnowingDNS::Handler');

my $config = App::AllKnowingDNS::Config->new;

################################################################################
# Check resolving PTR records without a config
################################################################################

my $qname = '7.c.e.2.3.4.e.f.f.f.b.d.9.1.2.0.0.c.c.c.e.0.0.1.8.8.d.4.1.0.0.2.ip6.arpa';
my $qclass = 'IN';
my $qtype = 'PTR';
my $peerhost = 'testsuite';
my ($rcode, $ans, $auth, $add) = reply_handler($config, 0, $qname, $qclass, $qtype, $peerhost);
is($rcode, 'NXDOMAIN', 'Query with empty config leads to NXDOMAIN');

################################################################################
# Check resolving PTR records with a config
################################################################################

my $zone = App::AllKnowingDNS::Zone->new;
$zone->network('2001:4d88:100e:ccc0::/64');
$zone->resolves_to('ipv6-%DIGITS%-blah.nutzer.raumzeitlabor.de');
$config->add_zone($zone);
($rcode, $ans, $auth, $add) = reply_handler($config, 0, $qname, $qclass, $qtype, $peerhost);
is($rcode, 'NOERROR', 'no error when handling query');
is(scalar @$ans, 1, 'one answer RR');
my ($rr) = @$ans;
is($rr->type, 'PTR', 'RR type is PTR');
is($rr->rdatastr, 'ipv6-0219dbfffe432ec7-blah.nutzer.raumzeitlabor.de.', 'RR ok');

################################################################################
# Check resolving hostnames to AAAA records
################################################################################

$qname = 'ipv6-0219dbfffe432ec7-blah.nutzer.raumzeitlabor.de';
$qclass = 'IN';
$qtype = 'AAAA';
$peerhost = 'testsuite';
($rcode, $ans, $auth, $add) = reply_handler($config, 0, $qname, $qclass, $qtype, $peerhost);
is($rcode, 'NOERROR', 'no error when handling query');
is(scalar @$ans, 1, 'one answer RR');
($rr) = @$ans;
is($rr->type, 'AAAA', 'RR type is AAAA');
is($rr->rdatastr, '2001:4d88:100e:ccc0:219:dbff:fe43:2ec7', 'RR ok');

################################################################################
# A pathetic example for resolving hostname to AAAA record: a /112 net
################################################################################

$config = App::AllKnowingDNS::Config->new;
$zone = App::AllKnowingDNS::Zone->new;
$zone->network('2001:4d88:100e:ccc0:1111:2222:3333:0000/112');
$zone->resolves_to('ipv6-%DIGITS%-blah.nutzer.raumzeitlabor.de');
$config->add_zone($zone);
$qname = 'ipv6-aaff-blah.nutzer.raumzeitlabor.de';
$qclass = 'IN';
$qtype = 'AAAA';
$peerhost = 'testsuite';
($rcode, $ans, $auth, $add) = reply_handler($config, 0, $qname, $qclass, $qtype, $peerhost);
is($rcode, 'NOERROR', 'no error when handling query');
is(scalar @$ans, 1, 'one answer RR');
($rr) = @$ans;
is($rr->type, 'AAAA', 'RR type is AAAA');
is($rr->rdatastr, '2001:4d88:100e:ccc0:1111:2222:3333:aaff', 'RR ok');

done_testing;
