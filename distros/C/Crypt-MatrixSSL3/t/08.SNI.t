use warnings;
use strict;
use Test::More;
use Test::Exception;

use Crypt::MatrixSSL3 qw(:all);

Crypt::MatrixSSL3::Open();

unless (Crypt::MatrixSSL3::capabilities() & SNI_ENABLED) {
    plan skip_all => "Server Name Identification not enabled - SNI_ENABLED not defined";
} else {
    plan tests => 7;
}

my $certFile            = 't/cert/server.crt';
my $privFile            = 't/cert/server.key';
my $privPass            = undef;
my $OCSPtest            = 't/cert/OCSPtest.der';
my $CTbuffer            = 't/cert/CTbuffer.sct';
my $CTfiles             = ['t/cert/CTfile1.sct', 't/cert/CTfile2.sct'];

my ($Server_Keys, $Server_SSL);

########
# Init #
########

lives_ok { $Server_Keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new (server)';
is PS_SUCCESS, $Server_Keys->load_rsa($certFile, $privFile, $privPass, undef),
    '$Server_Keys->load_rsa';
lives_ok { $Server_SSL = Crypt::MatrixSSL3::Server->new($Server_Keys, undef) }
    'Server->new';

my $server_index = Crypt::MatrixSSL3::create_SSL_server();

my $ssl_id = 420;
$Server_SSL->init_SNI($server_index, [
    {                                                               # virtual host 0
        'hostname' => '.*',                                         # hostname regex
        'cert' => $certFile,                                        # certificate
        'key' => $privFile,                                         # private key
        #'DH_param' => undef,                                       # no DH params
        'session_ticket_keys' => {                                  # session tickets
            'id' => '1234567890123456',                             # KEY - TLS session tickets - 16 bytes unique identifier
            'encrypt_key' => '12345678901234567890123456789012',    # KEY - TLS session tickets - 128/256 bit encryption key
            'hash_key' => '12345678901234567890123456789012',       # KEY - TLS session tickets - 256 bit hash key
        },
        'OCSP_staple' => $OCSPtest,
        'SCT_params' => $CTbuffer
    }
]);

cmp_ok $server_index, '>=', '0', '$Server_SSL->init_SNI($server_index, arrayref) first call';
cmp_ok Crypt::MatrixSSL3::refresh_OCSP_staple($server_index, 0, $OCSPtest), '==', PS_SUCCESS, 'Crypt::MatrixSSL3::refresh_OCSP_staple(server, vh_index, scalar)';
cmp_ok Crypt::MatrixSSL3::refresh_SCT_buffer($server_index, 0, $CTbuffer), '==', 1, 'Crypt::MatrixSSL3::refresh_SCT_buffer(server_index, vh_index, scalar)';
cmp_ok Crypt::MatrixSSL3::refresh_SCT_buffer($server_index, 0, $CTfiles), '==', 2, 'Crypt::MatrixSSL3::refresh_SCT_buffer(server_index, vh_index, arrayref)';

undef $Server_SSL;
undef $Server_Keys;

Crypt::MatrixSSL3::Close();
