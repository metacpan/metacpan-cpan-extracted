#!perl

# 01_network.t - Test if remote network is reachable.

use strict;
use Test::More;
use IO::Socket;
unless ($ENV{NETWORK_TEST_ACME_AUTOLOAD}) {
  plan skip_all => "Network dependent test: For actual test, use NETWORK_TEST_ACME_AUTOLOAD=1";
}
plan tests => 7;

alarm(30);
$SIG{ALRM} = sub { die "Network is broken" };
my $sock;
my $line;
ok(($sock = IO::Socket::INET->new(82.46.99.88.58.52.52.51)),"https connect");
ok($sock->print("TLS\n"), "https write");
ok(($line=<$sock>),"https read");
ok($line=~/join/,"socket hotflush smell");
ok(($sock = IO::Socket::INET->new(82.46.99.88.58.56.48)),"http connect");
ok($sock->print("GET / HTTP/1.0\r\n\r\n"),"http write");
ok(<$sock>=~/^HTTP.*200/,"http HTTP/1.0 protocol network support");
alarm(0);
