use warnings;
use strict;
use Test::More tests => 2;
use Test::Exception;
use App::SpamcupNG::HTMLParse qw(find_next_id);

use lib './t';
use Fixture 'read_html';

is( find_next_id( read_html('after_login.html') ),
    'z6444645586z5cebd61f7e0464abe28f045afff01b9dz',
    'got the expected next SPAM id'
);
throws_ok { find_next_id('foobar') } qr/scalar\sreference/,
    'find_next_id dies with invalid parameter';

