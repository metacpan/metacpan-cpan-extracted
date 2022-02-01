use warnings;
use strict;
use Test::More tests => 3;

use App::SpamcupNG::HTMLParse qw(find_message_age);
use lib './t';
use Fixture 'read_html';

my $result = find_message_age( read_html('sendreport_form_ok.html') );
is( ref($result), 'ARRAY', 'result is an array reference' );
is( $result->[0], 2,       'age has the expected value' );
is( $result->[1], 'hour', 'time unit is the expected one' );

# vim: filetype=perl

