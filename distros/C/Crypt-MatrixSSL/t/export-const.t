use warnings;
use strict;
use Test::More tests => 1;
use Test::Exception;

use Crypt::MatrixSSL;

throws_ok { $SSL_FLAGS_SERVER=2 }
    qr/read-only/, 'scalar constants exported read-only';

