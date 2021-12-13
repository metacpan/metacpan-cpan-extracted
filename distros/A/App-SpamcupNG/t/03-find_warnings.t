use warnings;
use strict;
use Test::More tests => 2;
use Test::Exception;
use App::SpamcupNG::HTMLParse qw(find_warnings);

use lib './t';
use Fixture 'read_html';

is_deeply(
    find_warnings( read_html('sendreport_form_ok.html') ),
    [   'Possible forgery. Supposed receiving system not associated with any of your mailhosts',
        'Yum, this spam is fresh!'
    ],
    'get the expected warnings'
);

throws_ok { find_warnings('foobar') } qr/scalar\sreference/,
    'find_warnings dies with invalid parameter';

