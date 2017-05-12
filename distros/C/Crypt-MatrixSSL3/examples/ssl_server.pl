#!/usr/bin/perl
use warnings;
use strict;
use blib;
use IO::Socket;
use Crypt::MatrixSSL3;
require 'examples/functions.pl';

# Process arguments:

my ($PORT) = @ARGV==1 ? ($ARGV[0])
           :            (4433)
           ;

warn <<"EOUSAGE";
Crypt::MatrixSSL3 sample SSL server.
Usage: $0 [port]
Starting https server on port ${PORT}
EOUSAGE

# Initialize vars:

my ($srvsock, $sock, $eof);                     # for socket i/o
my ($in, $out, $appIn, $appOut) = (q{}) x 4;    # ssl and app buffers
my ($handshakeIsComplete, $err);                # ssl state
my ($ssl, $keys);                               # for MatrixSSL

my $crt = 't/cert/server.crt;t/cert/testCA.crt';
my $key = 't/cert/server.key';

# Initialize MatrixSSL (as server):

$keys = Crypt::MatrixSSL3::Keys->new();
if (my $rc = $keys->load_rsa($crt, $key, undef, undef)) {
    die 'load_rsa: '.get_ssl_error($rc)."\n"
}
$ssl = Crypt::MatrixSSL3::Server->new($keys, undef);

# Socket I/O:

$srvsock = IO::Socket::INET->new(Listen=>5, LocalPort=>$PORT, ReuseAddr=>1)
    or die 'unable to start server';
$sock = $srvsock->accept();
$sock->blocking(0);

my $processed;  # flag: true if client request was processed
while (!$eof && !$err && !($processed && !length $out)) {
    # Processing client request and sending reply.
    if (!$processed && $appIn =~ /\A(.*?\r\n\r\n)/ms) {
        $appOut = "HTTP/1.0 200 OK\r\nServer: Crypt::MatrixSSL3\r\n\r\n"
                . "Below is copy of your request headers:\r\n$1";
        $processed = 1;
    }
    # I/O
    $eof = nb_io($sock, $in, $out);
    $err = ssl_io($ssl, $in, $out, $appIn, $appOut, $handshakeIsComplete);
    if ($err eq 'close') {
        $err = undef;
        $sock->blocking(1);
        my $n = syswrite $sock, $out;
        die "syswrite: $!" if !defined $n;
        last;
    }
}

close $sock or die "close: $!";
close $srvsock or die "close: $!";

# Process result:

print $appIn;
die $err if $err;
