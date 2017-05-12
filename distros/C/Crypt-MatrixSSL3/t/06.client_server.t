use warnings;
use strict;
use Test::More tests => 72;
use Test::Exception;

use Crypt::MatrixSSL3 qw(:all);

Crypt::MatrixSSL3::Open();

my $certFile            = 't/cert/server.crt';
my $privFile            = 't/cert/server.key';
my $privPass            = undef;
my $trustedCAcertFiles  = 't/cert/testCA.crt';

my ($Server_Keys, $Client_Keys);
my ($Server_SSL, $Client_SSL);

########
# Init #
########

lives_ok { $Server_Keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new (server)';
is PS_SUCCESS, $Server_Keys->load_rsa($certFile, $privFile, $privPass, undef),
    '$Server_Keys->load_rsa';
lives_ok { $Server_SSL = Crypt::MatrixSSL3::Server->new($Server_Keys, undef) }
    'Server->new';

lives_ok { $Client_Keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new (client)';
is PS_SUCCESS, $Client_Keys->load_rsa(undef, undef, undef, $trustedCAcertFiles),
    '$Client_Keys->load_rsa';
lives_ok { $Client_SSL = Crypt::MatrixSSL3::Client->new($Client_Keys, undef, undef, sub{0}, undef, undef, undef) }
    'Client->new';

#############
# Handshake #
#############

my ($client2server, $server2client) = (q{}, q{});
my ($client_rc, $server_rc);
while (1) {
    $server_rc = _decode($Server_SSL, $client2server, $server2client);
    $client_rc = _decode($Client_SSL, $server2client, $client2server);
    last if $client_rc || $server_rc;
}
is 1, $server_rc, 'handshake complete (server)';
is 1, $client_rc, 'handshake complete (client)';
ok !length $client2server, 'client outbuf empty after handshake';
ok !length $server2client, 'server outbuf empty after handshake';

#######
# I/O #
#######

# Simple string, twice

my $s   = "Hello MatrixSSL!\0\n";
my $tmp = $s;
my $buf;

ok $Client_SSL->encode_to_outdata($s) > 0,
    '$Client_SSL->encode_to_outdata';
is $tmp, $s,
    q{encode_to_outdata doesn't destroy input string};
is undef, _decode($Client_SSL, $server2client, $client2server);
ok length $client2server,
    'got some outbuf (client)';
$tmp = $client2server;
ok $Client_SSL->encode_to_outdata($s) > 0,
    '$Client_SSL->encode_to_outdata';
is undef, _decode($Client_SSL, $server2client, $client2server);
ok length $tmp < length $client2server,
    'outbuf grow (client)';

is undef, _decode($Server_SSL, $client2server, $server2client, $buf);
is $buf, $s.$s,
    'decoded ok (server)';
ok !length $client2server,
    'outbuf empty (client)';
ok !length $server2client,
    'outbuf empty (server)';

# SSL_MAX_PLAINTEXT_LEN

$s = 'abc' x 123456;
$tmp = $s;
$buf = q{};
while (length $tmp) {
    ok $Client_SSL->encode_to_outdata(substr($tmp, 0, SSL_MAX_PLAINTEXT_LEN, q{})) > 0,
        'encode_to_outdata up to SSL_MAX_PLAINTEXT_LEN (client)';
}
    is undef, _decode($Client_SSL, $server2client, $client2server),
        'encoding';
while (length $client2server) {
    is undef, _decode($Server_SSL, $client2server, $server2client, $buf),
        'decoding';
}
ok $buf eq $s,
    'string split into SSL_MAX_PLAINTEXT_LEN chains decoded ok';
ok !length $client2server,
    'outbuf empty (client)';
ok !length $server2client,
    'outbuf empty (server)';

# More than SSL_MAX_PLAINTEXT_LEN

#$s = 'x' x (SSL_MAX_PLAINTEXT_LEN+1);
#is $Client_SSL->encode_to_outdata($s), PS_LIMIT_FAIL,
#    'encode_to_outdata SSL_MAX_PLAINTEXT_LEN+1 failed';

#######
# Fin #
#######

undef $Server_SSL;
undef $Client_SSL;
undef $Server_Keys;
undef $Client_Keys;
ok 1, 'matrixSslClose';


###########
# Helpers #
###########

sub _decode {
    my ($ssl) = @_; # other 3 params must be modified in place
    while (length $_[1]) {
        my $rc = $ssl->received_data($_[1], my $buf);
RC:
        if    ($rc == MATRIXSSL_REQUEST_SEND)       { last          }
        elsif ($rc == MATRIXSSL_REQUEST_RECV)       { next          }
        elsif ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) { return 1      }
        elsif ($rc == MATRIXSSL_RECEIVED_ALERT)     { alert($buf); return -1 }
        elsif ($rc == MATRIXSSL_APP_DATA)           { $_[3].=$buf   }
        elsif ($rc == MATRIXSSL_SUCCESS)            { last          }
        else                                        { die error($rc)}
        $rc = $ssl->processed_data($buf);
        goto RC;
    }
    while (my $n = $ssl->get_outdata($_[2])) {
        my $rc = $ssl->sent_data($n);
        if    ($rc == MATRIXSSL_REQUEST_SEND)       { next          }
        elsif ($rc == MATRIXSSL_SUCCESS)            { last          }
        elsif ($rc == MATRIXSSL_REQUEST_CLOSE)      { return -1     }
        elsif ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) { return 1      }
        else                                        { die error($rc)}
    }
    return;
}

sub error {
    my $rc = get_ssl_error($_[0]);
    return sprintf "MatrixSSL error %d: %s\n", $rc, $rc;
}
sub alert {
    my ($level, $descr) = get_ssl_alert($_[0]);
    diag sprintf "MatrixSSL alert: level %d: %s, desc %d: %s\n", $level, $level, $descr, $descr;
    return;
}

Crypt::MatrixSSL3::Close();
