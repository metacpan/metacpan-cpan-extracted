use warnings;
use strict;
use Test::More tests => 4;
use Test::Exception;
use App::SpamcupNG::HTMLParse qw(find_warnings);

use lib './t';
use Fixture 'read_html';

my @mail_host = (
    'Possible forgery. Supposed receiving system not associated with any of your mailhosts',
    'Will not trust this Received line.'
    );

my $found_ref = find_warnings( read_html('sendreport_form_ok.html') );

is( scalar( @{$found_ref} ), 2, 'Got the expected number of warnings' );
is( $found_ref->[0]->message(),
    join( '. ', @mail_host ),
    'Go the mailhost warning'
    ) or diag( explain( $found_ref->[0] ) );
is( $found_ref->[1]->message(),
    'Yum, this spam is fresh!',
    'Got the "yum" warning'
    );

throws_ok { find_warnings('foobar') } qr/scalar\sreference/,
    'find_warnings dies with invalid parameter';

