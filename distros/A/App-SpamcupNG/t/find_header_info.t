use warnings;
use strict;
use Test::More tests => 6;

use App::SpamcupNG::HTMLParse qw(find_header_info);
use lib './t';
use Fixture 'read_html';

my $result = find_header_info( read_html('sendreport_form_ok.html') );
is( ref($result),      'HASH',             'result is a hash reference' );
is( $result->{mailer}, 'Smart_Send_4_4_2', 'mailer has the expected value' );
is( $result->{content_type},
    'multipart/mixed', 'content_type has the expected value' );

$result = find_header_info( read_html('missing_sendreport_form.html') );
is( ref($result),      'HASH',             'result is a hash reference' );
is( $result->{mailer}, undef, 'mailer has the expected value' );
is( $result->{content_type},
    'multipart/alternative;charset="utf-8"', 'content_type has the expected value' );

# vim: filetype=perl

