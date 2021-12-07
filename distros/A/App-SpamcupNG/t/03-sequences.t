use warnings;
use strict;
use Test::More tests => 9;
use Test::Exception;
use App::SpamcupNG::HTMLParse qw(find_next_id find_errors find_warnings);

use lib './t';
use Fixture 'read_html';

is( find_next_id( read_html('after_login.html') ),
    'z6444645586z5cebd61f7e0464abe28f045afff01b9dz',
    'got the expected next SPAM id'
);
throws_ok { find_next_id('foobar') } qr/scalar\sreference/,
    'find_next_id dies with invalid parameter';

my $errors_ref = find_errors( read_html('failed_load_header.html') );
is( ref($errors_ref), 'ARRAY',
    'result from find_errors is an array reference' );

is_deeply(
    $errors_ref,
    ['Failed to load spam header: 64446486 / cebd6f7e464abe28f4afffb9d'],
    'get the expected "load SPAM header" error'
);

$errors_ref = find_errors( read_html('mailhost_problem.html') );
is( ref($errors_ref), 'ARRAY',
    'result from find_errors is an array reference' );
is_deeply(
    $errors_ref,
    [   'Mailhost configuration problem, identified internal IP as source',
        'No source IP address found, cannot proceed.',
        'Nothing to do.'
    ],
    'get the expected errors'
);
throws_ok { find_errors('foobar') } qr/scalar\sreference/,
    'find_errors dies with invalid parameter';

is_deeply(
    find_warnings( read_html('sendreport_form_ok.html') ),
    [   'Possible forgery. Supposed receiving system not associated with any of your mailhosts',
        'Yum, this spam is fresh!'
    ],
    'get the expected warnings'
);

throws_ok { find_warnings('foobar') } qr/scalar\sreference/,
    'find_warnings dies with invalid parameter';

