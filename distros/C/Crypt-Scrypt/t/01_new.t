use strict;
use warnings;
use Test::More;
use Crypt::Scrypt;

new_ok('Crypt::Scrypt' => ['Your key']);
new_ok('Crypt::Scrypt' => [key => 'Your key']);

{
    local $@;
    eval { Crypt::Scrypt->new };
    like($@, qr/^'key' is required/, 'key is required');
}

can_ok('Crypt::Scrypt', qw(encrypt decrypt));

done_testing;
