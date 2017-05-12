use warnings;
use strict;
use Test::More;
use Test::Exception;

use Crypt::MatrixSSL3 qw(:all);

Crypt::MatrixSSL3::Open();

unless (Crypt::MatrixSSL3::capabilities() & OCSP_STAPLES_ENABLED) {
    plan skip_all => "OCSP staples not enabled - OCSP_STAPLES_ENABLED not defined";
} else {
    plan tests => 8;
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

$Server_SSL->set_server_params($server_index, {
    'ALPN' => ['proto1', 'proto2']
});

cmp_ok $server_index, '>=', '0', '$Server_SSL->set_server_params($server_index, params) first call';
cmp_ok $Server_Keys->load_OCSP_response($OCSPtest), '==', PS_SUCCESS, 'Crypt::MatrixSSL3::refresh_OCSP_staple(server_index, undef, file)';
cmp_ok $Server_Keys->load_SCT_response($CTbuffer), '==', 1, 'Crypt::MatrixSSL3::refresh_SCT_buffer(server_index, undef, file)';
cmp_ok $Server_Keys->load_SCT_response($CTfiles), '==', 2, 'Crypt::MatrixSSL3::refresh_SCT_buffer(server_index, undef, [files])';
cmp_ok Crypt::MatrixSSL3::refresh_ALPN_data($server_index, undef, ['proto3', 'proto4']), '==', 2, 'Crypt::MatrixSSL3::refresh_ALPN_data(server_index, undef, [protocols])';

undef $Server_SSL;
undef $Server_Keys;

Crypt::MatrixSSL3::Close();
