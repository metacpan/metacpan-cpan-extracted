#!/usr/bin/perl

use strict;

use Test::More tests => 5;
use Test::Exception;

use Crypt::NSS config_dir => "db";

throws_ok {
    Net::NSS::SSL->create_socket("icmp");
} qr/Unknown socket type 'icmp'/;

my $socket = Net::NSS::SSL->create_socket("tcp");
ok($socket);
isa_ok($socket, "Net::NSS::SSL");

# Since we're not connected these should throw an exception
throws_ok {
    $socket->peerhost();
} qr/Can't get peeraddr/;

throws_ok {
    $socket->peerport();
} qr/Can't get peeraddr/;