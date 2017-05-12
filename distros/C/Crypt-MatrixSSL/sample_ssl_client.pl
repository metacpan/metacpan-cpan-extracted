#!/usr/bin/perl

use IO::Socket;
use Crypt::MatrixSSL;
require 'sample_functions.pl';

# Process arguments:

my ($HOST, $PORT) = @ARGV==2 ? @ARGV
                  : @ARGV==1 ? ($ARGV[0], 'https')
                  :            ('google.com', 'https')
                  ;

warn <<"EOUSAGE";
Crypt::MatrixSSL sample SSL client.
Usage: $0 [hostname [port]]
Now downloading: https://${HOST}:${PORT}/
EOUSAGE

# Initialize vars:

my ($sock, $eof);                               # for socket i/o
my ($in, $out, $appIn, $appOut) = (q{}) x 4;    # ssl and app buffers
my ($handshakeIsComplete, $err);                # ssl state
my ($ssl, $keys, $sessionId);                   # for MatrixSSL

$appOut = "GET / HTTP/1.0\r\nHost: ${HOST}\r\n\r\n";

# Initialize MatrixSSL (as client):

matrixSslOpen()
    == 0 or die 'matrixSslOpen';
matrixSslReadKeys($keys, undef, undef, undef,
    '/etc/ssl/certs/ca-certificates.crt;t/cert/testca.crt')
    == 0 or die 'matrixSslReadKeys';
matrixSslNewSession($ssl, $keys, $sessionId, 0)
    == 0 or die 'matrixSslNewSession';
matrixSslEncodeClientHello($ssl, $out, 0)
    == 0 or die 'matrixSslEncodeClientHello';

# Socket I/O:

$sock = IO::Socket::INET->new("${HOST}:${PORT}")
    or die 'unable to connect to remote server';
$sock->blocking(0);

while (!$eof && !$err) {
    # I/O
    $eof = nb_io($sock, $in, $out);
    $err = ssl_io($ssl, $in, $out, $appIn, $appOut, $handshakeIsComplete);
}

close($sock);

# Deinitialize MatrixSSL:

matrixSslDeleteSession($ssl);
matrixSslFreeKeys($keys);
matrixSslClose();

# Process result:

print $appIn;
die $err if $err;

