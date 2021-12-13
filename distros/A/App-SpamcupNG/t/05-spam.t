use warnings;
use strict;
use Test::More tests => 2;
use App::SpamcupNG::HTMLParse qw(find_spam_header);
use File::Spec;

use lib './t';
use Fixture 'read_html';

my $parsed   = find_spam_header( read_html('sendreport_form_ok.html') );
my $expected = [
    'From: Alon Elkin <alon.elkien@gmail.com> (',
    'PHD. Hebrew to English and German Translator',
    ')',
    '------=_NextPart_001_1B4D_3C042781.4D516F77',
    'Content-Type: multipart/alternative;'
];

is( ref($parsed), 'ARRAY',
    'result from find_spam_header is an array reference' )
    or diag( explain($parsed) );
is_deeply( $parsed, $expected, 'result has the expected structure' )
    or diag( explain($parsed) );

