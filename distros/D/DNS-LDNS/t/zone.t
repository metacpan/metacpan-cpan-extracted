use Test::More tests => 16;

use FindBin qw/$Bin/;

use DNS::LDNS ':all';

BEGIN { use_ok('DNS::LDNS') };

# Create a new zone
my $z = DNS::LDNS::Zone->new;
isa_ok($z, 'DNS::LDNS::Zone', 'Create an empty zone');

# Fill inn a soa and some rrs
$z->set_soa(DNS::LDNS::RR->new(str => join(' ', qw/myzone.org 1000 IN SOA
    hostmaster.myzone.org. master.myzone.org. 2012113030 12345 1827 2345678
    87654/)));

is($z->soa->dname, 'myzone.org.', 'Found soa record');

my $rrs = DNS::LDNS::RRList->new;
$rrs->push(DNS::LDNS::RR->new(str => 'ns2.myzone.org 3600 IN A 192.168.100.2'),
	   DNS::LDNS::RR->new(str => 'ns2.myzone.org 3600 IN A 192.168.100.9'),
	   DNS::LDNS::RR->new(str => 'ns3.myzone.org 3600 IN A 192.168.100.2'),
	   DNS::LDNS::RR->new(str => 'ns1.myzone.org 3600 IN A 192.168.100.7'));

$z->set_rrs($rrs);
is($z->rrs->rr(0)->to_string, "ns2.myzone.org.\t3600\tIN\tA\t192.168.100.2\n",
    'Check first rr');
is($z->rrs->rr(3)->to_string, "ns1.myzone.org.\t3600\tIN\tA\t192.168.100.7\n",
    'Check last rr');

$z->sort;
is($z->rrs->rr(0)->to_string, "ns1.myzone.org.\t3600\tIN\tA\t192.168.100.7\n",
    'Check first rr after sorting');
is($z->rrs->rr(3)->to_string, "ns3.myzone.org.\t3600\tIN\tA\t192.168.100.2\n",
    'Check last rr after sorting');

# Read a zone from file
my $z2 = DNS::LDNS::Zone->new(
    filename => "$Bin/testdata/myzone.org", ttl => 100);

$z2->canonicalize;

like($z2->to_string, qr/\nns.ldns.myzone.org.\s+/, 'Canonicalize');

like($z2->to_string, qr/^myzone.org.\s+1000\s+IN\s+SOA\s+ldns.myzone.org.\s+ns.ldns.myzone.org.\s+2012113030\s+12345\s+1827\s+2345678\s+87654\s+/, 'Found soa rec');

like($z2->to_string, qr/ns.ldns.myzone.org.\s+4500\s+IN\s+A\s+192.168.100.2/, 'Found ns rec');

like($z2->to_string, qr/ns2.myzone.org.\s+5600\s+IN\s+AAAA\s+2001:dead:dead::2/, 'Found yet another ns rec');

is($z2->rrs->rr_count, 5, 'Zone has 5 rrs');

my $klist = DNS::LDNS::KeyList->new;
$klist->push(DNS::LDNS::Key->new(filename => "$Bin/testdata/key.private"));
$klist->key(0)->set_pubkey_owner(
	DNS::LDNS::RData->new(LDNS_RDF_TYPE_DNAME, 'myzone.org'));

my $z3 = $z2->sign($klist);

my $sigc = grep { $z3->rrs->rr($_)->type == LDNS_RR_TYPE_RRSIG }
   (0 .. $z3->rrs->rr_count - 1);
is($sigc, 10, 'Signed zone has 10 signatures');
my $nsecc = grep { $z3->rrs->rr($_)->type == LDNS_RR_TYPE_NSEC }
   (0 .. $z3->rrs->rr_count - 1);
is($nsecc, 4, 'Signed zone has 3 nsec recs');

my $z4 = $z2->sign_nsec3($klist, 1, 0, 2, 'ABC');

my $sigc3 = grep { $z4->rrs->rr($_)->type == LDNS_RR_TYPE_RRSIG }
   (0 .. $z4->rrs->rr_count - 1);
is($sigc3, 12, 'NSEC3-signed zone has 12 signatures');
my $nsecc3 = grep { $z4->rrs->rr($_)->type == LDNS_RR_TYPE_NSEC3 }
   (0 .. $z4->rrs->rr_count - 1);
is($nsecc3, 5, 'NSEC3-signed zone has 5 nsec recs');
