#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use App::Monport;

SKIP: {
    skip "Didn't find nmap executable", 2 unless eval { nmap_path() };

    my $host    = q(scanme.nmap.org);
    my $verbose = 1;
    my $open    = scan_ports( $host, $verbose );
    for my $expected (qw(22 80)) {
        ok( grep( $expected == $_, @$open ), "$host has port $expected open" );
    }
}
