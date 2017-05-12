use warnings;
use strict;
use Test::More tests => 3;
use Test::Exception;

use Crypt::MatrixSSL3;


my $Server_Keys = 0;
lives_ok { $Server_Keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new';
isnt $Server_Keys, 0, '$Server_Keys set';

undef $Server_Keys;
ok 1, 'matrixSslClose';

