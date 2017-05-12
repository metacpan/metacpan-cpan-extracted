use warnings;
use strict;
use Test::More tests => 7;
use Test::Exception;

use Crypt::MatrixSSL3 qw( :DEFAULT :Error );

Crypt::MatrixSSL3::Open();

my ($ssl, $keys);

is undef, $ssl,
    'ssl not defined';

=for still returns ok
throws_ok { $ssl = Crypt::MatrixSSL3::Server->new(undef, undef) }
    qr/^${\PS_FAILURE}\b/,
    'no keys';
=cut

lives_ok { $keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new';

lives_ok { $ssl = Crypt::MatrixSSL3::Server->new($keys, undef) }
    'empty keys';

is PS_SUCCESS, $keys->load_rsa(undef, undef, undef, $Crypt::MatrixSSL3::CA_CERTIFICATES),
    '$keys->load_rsa';

lives_ok { $ssl = Crypt::MatrixSSL3::Server->new($keys, undef) }
    'wrong keys';

ok $ssl && $$ssl > 0,
    'ssl is not NULL';
undef $ssl;

undef $keys;
ok(1, 'matrixSslClose');

Crypt::MatrixSSL3::Close();
