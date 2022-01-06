use warnings;
use strict;
use Test::More tests => 3;
use App::SpamcupNG::HTMLParse qw(find_receivers);

use lib './t';
use Fixture 'read_html';

my $receivers_ref = find_receivers( read_html('post_reporting.html') );
is( ref($receivers_ref), 'ARRAY', 'the returned value is a array reference' );
is( scalar( @{$receivers_ref} ),
    3, 'It has the expected number of receivers' );
is_deeply(
    $receivers_ref,
    [   q{/dev/null'ing report for google-abuse-bounces-reports@devnull.spamcop.net},
        'Spam report id 7151980235 sent to: dl_security_whois@navercorp.com',
        q{/dev/null'ing report for deliverabilityteam#epsilon.com@devnull.spamcop.net}
    ],
    'It has the expected receivers'
    );

