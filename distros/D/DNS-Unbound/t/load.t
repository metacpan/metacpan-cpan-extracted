#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Net::DNS::Parameters;

use_ok('DNS::Unbound');

ok( DNS::Unbound->unbound_version() );

diag( "Unbound version: " . DNS::Unbound->unbound_version() );

use Data::Dumper;
$Data::Dumper::Useqq = 1;

my $dns = DNS::Unbound->new();

eval {
    my $result = $dns->resolve( 'cannot.exist.invalid', 'NS' );

    isa_ok( $result, 'DNS::Unbound::Result', 'resolve() response' );

    is( $result->rcode(), Net::DNS::Parameters::rcodebyname('NXDOMAIN'), 'rcode()' );
    is( $result->{rcode}, Net::DNS::Parameters::rcodebyname('NXDOMAIN'), '{rcode}' );

    is( $result->secure(), 0, '!secure()' );
    is( $result->{secure}, 0, '!{secure}' );

    is( $result->bogus(), 0, '!bogus()' );
    is( $result->{bogus}, 0, '!{bogus}' );

    is( $result->why_bogus(), undef, 'why_bogus()' );
    is( $result->{'why_bogus'}, undef, '{why_bogus}' );

    is( $result->canonname(), undef, 'canonname()' );
    is( $result->{canonname}, undef, '{canonname}' );

    diag explain $result;

    # There often is a packet, even if there’s no data in it.
    # is_deeply( $result->answer_packet(), q<>, 'answer_packet() when there’s no data' );

    $result = $dns->resolve('com', 'NS');
    my @data = @{ $result->data() };

    is_deeply(
        $result->data(),
        $result->{'data'},
        'data() and {data}',
    );

    $_ = $dns->decode_name($_) for @data;

    diag explain \@data;

    is( $result->qtype(), Net::DNS::Parameters::typebyname('NS'), 'qtype()' );
    is( $result->{qtype}, Net::DNS::Parameters::typebyname('NS'), '{qtype}' );

    is( $result->qclass(), 1, 'qclass()' );
    is( $result->{qclass}, 1, '{qclass}' );

    is( $result->qname(), 'com', 'qname()' );
    is( $result->{qname}, 'com', '{qname}' );

    ok( $result->havedata(), 'havedata()' );
    ok( $result->{havedata}, '{havedata}' );

    is( $result->nxdomain(), 0, '!nxdomain()' );
    is( $result->{nxdomain}, 0, '!{nxdomain}' );

    my $net_dns_packet = Net::DNS::Packet->new( \$result->answer_packet() );

    if (my @answer = $net_dns_packet->answer()) {

        my $ns_obj = $answer[0];

        isa_ok( $ns_obj, 'Net::DNS::RR::NS', 'parse answer_packet() result' );

        is( $ns_obj->ttl(), $result->ttl(), 'ttl() match' );
        is( $ns_obj->ttl(), $result->{ttl}, '{ttl} match' );

        is( $ns_obj->class(), 'IN', 'class() match' );
        is( $ns_obj->type(), 'NS', 'type() match' );

        is( $ns_obj->owner(), $result->qname(), 'owner() match' );
        is( $ns_obj->owner(), $result->{qname}, 'owner() ({qname}) match' );

        # chop off trailing “.”
        is( $ns_obj->nsdname(), substr( $data[0], 0, -1 ), 'nsdname() match' );
    }
};

done_testing();
