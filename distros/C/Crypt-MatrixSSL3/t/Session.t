use warnings;
use strict;
use Test::More tests => 4;
use Test::Exception;

use Crypt::MatrixSSL3;

my $sess = Crypt::MatrixSSL3::SessID->new();
ok $sess, 'SessID->new';
throws_ok   { $$sess++ } qr/read-only/,
    'sslSession_t* is read-only';
lives_ok    { $sess->clear() }
    '$sess->clear';
undef $sess;
ok 1, 'matrixSslClose';

