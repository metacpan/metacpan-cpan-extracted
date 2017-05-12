use warnings;
use strict;
use Test::More tests => 15;

use Crypt::MatrixSSL;

my $certFile            = 't/cert/testserver.crt';
my $privFile            = 't/cert/testserver.key';
my $privPass            = undef;
my $trustedCAcertFiles  = 't/cert/testca.crt';

our ($Server_Keys, $Client_Keys);

########
# Init #
########

matrixSslOpen()
    == 0 or die 'matrixSslOpen';
matrixSslReadKeys($Server_Keys, $certFile, $privFile, $privPass, undef)
    == 0 or die 'matrixSslReadKeys (server)';
matrixSslReadKeys($Client_Keys, undef, undef, undef, $trustedCAcertFiles)
    == 0 or die 'matrixSslReadKeys (client)';

our $Client_sessionId   = undef;
our ($Server_SSL, $Client_SSL);

matrixSslNewSession($Server_SSL, $Server_Keys, undef, $SSL_FLAGS_SERVER)
    == 0 or die 'matrixSslNewSession (server)';
matrixSslNewSession($Client_SSL, $Client_Keys, $Client_sessionId, 0)
    == 0 or die 'matrixSslNewSession (client)';

my $cipherSuite         = 0;
my ($client2server, $server2client) = (q{}, q{});

#############
# Handshake #
#############

matrixSslEncodeClientHello($Client_SSL, $client2server, $cipherSuite)
    == 0 or die 'matrixSslEncodeClientHello';
while (matrixSslHandshakeIsComplete($Client_SSL) != 1 and
        (length $client2server or length $server2client)) {
    _decode($Server_SSL, $client2server, $server2client);
    _decode($Client_SSL, $server2client, $client2server);
}
is(matrixSslHandshakeIsComplete($Client_SSL), 1, 'handshake complete');
is(length($client2server), 0, 'client2server empty after handshake');
is(length($server2client), 0, 'server2client empty after handshake');

#######
# I/O #
#######

# Simple string, twice

my $s   = "Hello MatrixSSL!\0\n";
my $tmp = $s;

matrixSslEncode($Client_SSL, $s, $client2server)
    >= 0 or die 'matrixSslEncode (client)';
is($tmp, $s,
    q{matrixSslEncode doesn't destroy input string});
$tmp = $client2server;
matrixSslEncode($Client_SSL, $s, $client2server)
    >= 0 or die 'matrixSslEncode (client)';
ok(length $tmp < length $client2server,
    'matrixSslEncode append to output buffer');

my ($rc, $error, $alertLevel, $alertDescription);
$rc = matrixSslDecode($Server_SSL, $client2server, $server2client,
    $error, $alertLevel, $alertDescription);
is($rc, $SSL_PROCESS_DATA,
    'matrixSslDecode return SSL_PROCESS_DATA');
is($server2client, $s,
    '... first string decoded ok');
$rc = matrixSslDecode($Server_SSL, $client2server, $server2client,
    $error, $alertLevel, $alertDescription);
is($rc, $SSL_PROCESS_DATA,
    'matrixSslDecode return SSL_PROCESS_DATA');
is($server2client, $s.$s,
    '... second string decoded ok, matrixSslDecode append to output buffer');
is(length($client2server), 0,
    'no more data for decoding');

# SSL_MAX_PLAINTEXT_LEN

$s = 'abc' x 1234567;
$tmp = $s;
$client2server = $server2client = q{};
while (length $tmp) {
    $rc = matrixSslEncode($Client_SSL,
        substr($tmp, 0, $SSL_MAX_PLAINTEXT_LEN, q{}), $client2server)
        >= 0 or die 'matrixSslEncode up to SSL_MAX_PLAINTEXT_LEN';
}
while (length $client2server) {
    matrixSslDecode($Server_SSL, $client2server, $server2client,
        $error, $alertLevel, $alertDescription)
        == $SSL_PROCESS_DATA or die 'matrixSslDecode return non- SSL_PROCESS_DATA';
}
ok($server2client eq $s,
    'string split into SSL_MAX_PLAINTEXT_LEN chains decoded ok');

# More than SSL_MAX_PLAINTEXT_LEN

$s = 'x' x ($SSL_MAX_PLAINTEXT_LEN+1);
$client2server = $server2client = q{};
$rc = matrixSslEncode($Client_SSL, $s, $client2server);
ok($rc >= 0,
    'matrixSslEncode SSL_MAX_PLAINTEXT_LEN+1');
$rc = matrixSslDecode($Server_SSL, $client2server, $server2client,
    $error, $alertLevel, $alertDescription);
is($rc, $SSL_ERROR,
    'matrixSslDecode return SSL_ERROR');

$s = 'x' x ($SSL_MAX_PLAINTEXT_LEN+2048);
$client2server = $server2client = q{};
$rc = matrixSslEncode($Client_SSL, $s, $client2server);
is($rc, $SSL_FULL,
    'matrixSslEncode SSL_MAX_PLAINTEXT_LEN+2048 return SSL_FULL');

$s = 'x' x ($SSL_MAX_PLAINTEXT_LEN+2049);
$client2server = $server2client = q{};
$rc = matrixSslEncode($Client_SSL, $s, $client2server);
is($rc, $SSL_ERROR,
    'matrixSslEncode SSL_MAX_PLAINTEXT_LEN+2049 return SSL_ERROR');

#######
# Fin #
#######

matrixSslFreeKeys($Server_Keys);
matrixSslFreeKeys($Client_Keys);
matrixSslClose();

sub _decode {
    my ($ssl, $in, $out) = @_;
    if (length $in) {
        my ($rc, $error, $alertLevel, $alertDescription);
        $rc = matrixSslDecode($ssl, $in, $out,
            $error, $alertLevel, $alertDescription);
        if ($rc == $SSL_SUCCESS || $rc == $SSL_SEND_RESPONSE) {
            @_[1,2] = ($in, $out);
        }
        else {
            die sprintf "DECODE_Client handshake error:\n".
                "\trc=%s error=%s\n".
                "\talertLevel=%s alertDescription=%s\n",
                $Crypt::MatrixSSL::mxSSL_RETURN_CODES{$rc},
                $SSL_alertDescription{$error},
                $SSL_alertLevel{$alertLevel},
                $SSL_alertDescription{$alertDescription};
        }
    }
}
