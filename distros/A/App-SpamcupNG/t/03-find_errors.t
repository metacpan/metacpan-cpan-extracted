use warnings;
use strict;
use Test::More tests => 7;
use Test::Exception;
use App::SpamcupNG::HTMLParse qw(find_errors);

use lib './t';
use Fixture 'read_html';

note('Failure to load SPAM header');
my $errors_ref = find_errors( read_html('failed_load_header.html') );
is( ref($errors_ref), 'ARRAY',
    'result from find_errors is an array reference' );
is_deeply(
    $errors_ref,
    ['Failed to load spam header: 64446486 / cebd6f7e464abe28f4afffb9d'],
    'get the expected "load SPAM header" error'
);

note('Mailhost problem');
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

note('Bounce error');
$errors_ref = find_errors( read_html('bounce_error.html') );
is( ref($errors_ref), 'ARRAY',
    'result from find_errors is an array reference' );
is_deeply(
    $errors_ref,
    [   'Your email address, glasswalk3r@yahoo.com.br has returned a bounce:',
        'Subject: Delivery Status Notification (Failure)',
        q{Reason: 5.4.7 - Delivery expired (message too old) 'DNS Soft Error looking up yahoo=}
    ],
    'get the expected bounce error'
);

throws_ok { find_errors('foobar') } qr/scalar\sreference/,
    'find_errors dies with invalid parameter';
