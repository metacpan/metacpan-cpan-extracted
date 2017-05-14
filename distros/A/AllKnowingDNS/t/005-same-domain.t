#!perl
# vim:ts=4:sw=4:expandtab
#
# Verify that the App::AllKnowingDNS::Handler works when having multiple zones
# configured that only differ in the first part of the domain (e.g.
# foo-%DIGITS%.example.net and bar-%DIGITS%.example.net).

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

my $qname = '1.0.0.0.2.9.1.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.0.a.5.1.0.0.a.2.ip6.arpa';
my $qclass = 'IN';
my $qtype = 'PTR';
my $peerhost = 'testsuite';
my ($rcode, $ans, $auth, $add) = reply_handler($config, 0, $qname, $qclass, $qtype, $peerhost);
is($rcode, 'NXDOMAIN', 'Query with empty config leads to NXDOMAIN');

################################################################################
# Check resolving PTR records with a config
################################################################################

my $zone = App::AllKnowingDNS::Zone->new;
$zone->network('2001:840:5000:2::/64');
$zone->resolves_to('oslo-%DIGITS%.ipv6.monsternett.net');
$config->add_zone($zone);

$zone = App::AllKnowingDNS::Zone->new;
$zone->network('2a00:15a0::192:/64');
$zone->resolves_to('mail-%DIGITS%.ipv6.monsternett.net');
$config->add_zone($zone);

$zone = App::AllKnowingDNS::Zone->new;
$zone->network('2a00:15a0:2::192:/64');
$zone->resolves_to('web-%DIGITS%.ipv6.monsternett.net');
$config->add_zone($zone);

($rcode, $ans, $auth, $add) = reply_handler($config, 0, $qname, $qclass, $qtype, $peerhost);
is($rcode, 'NOERROR', 'no error when handling query');
is(scalar @$ans, 1, 'one answer RR');
my ($rr) = @$ans;
is($rr->type, 'PTR', 'RR type is PTR');
is($rr->rdatastr, 'web-0000000001920001.ipv6.monsternett.net.', 'RR ok');

################################################################################
# Check resolving hostnames to AAAA records
################################################################################

$qname = 'web-0000000001920001.ipv6.monsternett.net';
$qclass = 'IN';
$qtype = 'AAAA';
$peerhost = 'testsuite';
($rcode, $ans, $auth, $add) = reply_handler($config, 0, $qname, $qclass, $qtype, $peerhost);
is($rcode, 'NOERROR', 'no error when handling query');
is(scalar @$ans, 1, 'one answer RR');
($rr) = @$ans;
is($rr->type, 'AAAA', 'RR type is AAAA');
ok(($rr->rdatastr eq '2a00:15a0:2:0:0:0:192:1') ||
   ($rr->rdatastr eq '2a00:15a0:2::192:1'), 'RR ok');

done_testing;
