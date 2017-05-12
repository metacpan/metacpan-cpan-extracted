use warnings;
use strict;
use Test::More tests => 3;
use Test::Exception;

use Crypt::MatrixSSL3;

Crypt::MatrixSSL3::Open();

my $certFile            = 't/cert/server.crt';
my $privFile            = 't/cert/server.key';
my $privPass            = undef;
my $trustedCAcertFiles  = 't/cert/testCA.crt';

my $Server_Keys         = 0;

lives_ok { $Server_Keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new';

my $rc = $Server_Keys->load_rsa($certFile, $privFile, $privPass, undef);
is $rc, PS_SUCCESS, '$Server_Keys->load_rsa';

undef $Server_Keys;
ok 1, 'matrixSslClose';

Crypt::MatrixSSL3::Close();
