use warnings;
use strict;
use Test::More tests => 12;

use App::SpamcupNG::HTMLParse qw(find_header_info);
use lib './t';
use Fixture 'read_html';

my $source = 'sendreport_form_ok.html';
note($source);
my $result = find_header_info( read_html($source) );
is( ref($result),      'HASH',             'result is a hash reference' );
is( $result->{mailer}, 'Smart_Send_4_4_2', 'mailer has the expected value' );
is( $result->{content_type},
    'multipart/mixed', 'content_type has the expected value' );
is( $result->{charset}, undef, 'charset has the expected value' );

$source = 'missing_sendreport_form.html';
note($source);
$result = find_header_info( read_html($source) );
is( ref($result),      'HASH', 'result is a hash reference' );
is( $result->{mailer}, undef,  'mailer has the expected value' );
is( $result->{content_type},
    'multipart/alternative', 'content_type has the expected value' );
is( $result->{charset}, 'utf-8', 'charset has the expected value' );

$source = 'boundary.html';
note($source);
$result = find_header_info( read_html($source) );
is( ref($result),      'HASH', 'result is a hash reference' );
is( $result->{mailer}, undef,  'mailer has the expected value' );
is( $result->{content_type},
    'multipart/alternative', 'content_type has the expected value' );
is( $result->{charset}, undef, 'charset has the expected value' );

# vim: filetype=perl

