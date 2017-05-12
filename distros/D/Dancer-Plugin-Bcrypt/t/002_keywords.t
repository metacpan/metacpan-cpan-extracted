use Test::More import => ['!pass'],  tests => 2;

use strict;
use warnings;

use Dancer::Plugin::Bcrypt;

ok(
    bcrypt('What a secure passphrase this is...')
);

ok(
    bcrypt_validate_password(
        'What a secure passphrase this is...',
        '$2a$04$KcIfei749yS4dGakQByOM.mKK6CpktFwoBiijHuyMyN.SMzT4sKNK'
    )
);

