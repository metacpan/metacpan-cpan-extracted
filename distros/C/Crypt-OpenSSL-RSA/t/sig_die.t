use strict;
use Test::More;

use lib 't/fakelib';

my $handler_called;
$SIG{__DIE__} = sub { ++$handler_called };

require Crypt::OpenSSL::RSA;

plan tests => 1;

ok !$handler_called, 'outer $SIG{__DIE__} handler not called';
