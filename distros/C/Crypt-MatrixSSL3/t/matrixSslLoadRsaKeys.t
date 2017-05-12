use warnings;
use strict;
use Test::More tests => 17;
use Test::Exception;

use Crypt::MatrixSSL3 qw( :DEFAULT :Error );

Crypt::MatrixSSL3::Open();

my $trustedCAcertFiles  = 't/cert/testCA.crt';
my $certFile            = 't/cert/server.crt';
my $privFile            = 't/cert/server.key';
my $privPass            = undef;

my $trustedCA; if(open(IN,'<',"$trustedCAcertFiles.der")) {local $/; $trustedCA=<IN>; close(IN); }
my $cert; if(open(IN,'<',"$certFile.der")) {local $/; $cert=<IN>; close(IN); }
my $priv; if(open(IN,'<',"$privFile.der")) {local $/; $priv=<IN>; close(IN); }

my $privFile_des3       = $privFile.'.des3';
my $privPass_des3       = 'test';

is PS_SUCCESS, _load_rsa($certFile, $privFile, $privPass, undef),
    'server: NO PASSWORD';
is PS_FAILURE, _load_rsa($certFile, $privFile, '', undef),
    'server: EMPTY PASSWORD';
is PS_FAILURE, _load_rsa($certFile, $privFile, 'a_n_y', undef),
    'server: ANY PASSWORD';
is PS_SUCCESS, _load_rsa(undef, undef, undef, $trustedCAcertFiles),
    'client';
is PS_SUCCESS, _load_rsa($certFile, $privFile, $privPass, $trustedCAcertFiles),
    'both';
is PS_SUCCESS, _load_rsa_mem($cert, $priv, undef),
    'Mem server';
is PS_SUCCESS, _load_rsa_mem(undef, undef, $trustedCA),
    'Mem client';
is PS_SUCCESS, _load_rsa_mem($cert, $priv, $trustedCA),
    'Mem both';

is PS_SUCCESS, _load_rsa($certFile, $privFile_des3, $privPass_des3, undef),
    'server: encrypted des3, RIGHT PASSWORD';
is PS_ARG_FAIL, _load_rsa($certFile, $privFile_des3, $privPass, undef),
    'server: encrypted des3, NO PASSWORD';
is PS_FAILURE, _load_rsa($certFile, $privFile_des3, '', undef),
    'server: encrypted des3, EMPTY PASSWORD';
is PS_FAILURE, _load_rsa($certFile, $privFile_des3, 'WrOnG', undef),
    'server: encrypted des3, WRONG PASSWORD';

is PS_SUCCESS, _load_rsa(undef, undef, undef, undef),
    'no keys';
is PS_PARSE_FAIL, _load_rsa($0, undef, undef, undef),
    'bad certFile';
is PS_PARSE_FAIL, _load_rsa_mem('bad cert', undef, undef),
    'bad cert';
is PS_PLATFORM_FAIL, _load_rsa(undef, undef, undef, 'no such file'),
    'no such certFile';
is PS_CERT_AUTH_FAIL, _load_rsa($certFile, undef, undef, undef),
    'certFile without priv key';

# TODO MatrixSSL-3.3 crash (glibc double-free) on this test:
# is PS_CERT_AUTH_FAIL, _load_rsa_mem($cert, undef, undef),
#     'cert without priv key';

# TODO MatrixSSL-3.3 doesn't support public key algorithms used in that file:
# is PS_UNSUPPORTED_FAIL, _load_rsa(undef, undef, undef, '/etc/ssl/certs/ca-certificates.crt'),
#     '';


sub _load_rsa {
    my $keys = Crypt::MatrixSSL3::Keys->new();
    return $keys->load_rsa($_[0], $_[1], $_[2], $_[3]);
}

sub _load_rsa_mem {
    my $keys = Crypt::MatrixSSL3::Keys->new();
    return $keys->load_rsa_mem($_[0], $_[1], $_[2]);
}

Crypt::MatrixSSL3::Close();
