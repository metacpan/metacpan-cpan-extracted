#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Test::DescribeMe 'author';

use Net::DNS::Nameserver;
use Net::DNS::RR;

use File::Temp;
use Socket;

use_ok('DNS::Unbound');

my $ns = eval {
    die "Need superuser access to run this test!\n" if $>;

    Net::DNS::Nameserver->new(
        Verbose => 1,
        ReplyHandler => sub {
            my ( $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;
            my ( $rcode, @ans, @auth, @add );

            if ( $qtype eq "A" && $qname eq "myhost.local" ) {
                my ( $ttl, $rdata ) = ( 3600, "127.0.0.1" );
                my $rr = Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
                push @ans, $rr;
                $rcode = "NOERROR";
            }
            else {
                die "Bad query: $qname, $qclass, $qtype, $peerhost, $query";
            }

            # mark the answer as authoritative (by setting the 'aa' flag)
            my $headermask = {aa => 1};

            # specify EDNS options  { option => value }
            my $optionmask = {};

            return ( $rcode, \@ans, \@auth, \@add, $headermask, $optionmask );
        },
    );
};

SKIP: {
    skip "Failed to start nameserver: $@", 1 if !$ns;

    my $pid;
    $pid = fork or do {
        die "fork(): $!" if !defined $pid;

        $ns->main_loop();
    };

    undef $ns;

    my ($fh, $fpath) = File::Temp::tempfile( CLEANUP => 1 );

    print $fh "nameserver 127.0.0.1$/";
    close $fh;

    my $dns = DNS::Unbound->new()->resolvconf($fpath);

    my $result = $dns->resolve( 'myhost.local', 'A' );

    is(
        "@{$result->data()}",
        pack( 'C*', 127, 0, 0, 1 ),
        'query returns as expected',
    );

    kill 'TERM', $pid;
}

done_testing();
