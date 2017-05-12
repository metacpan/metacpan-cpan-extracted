use strict;
use warnings;

use utf8;
use charnames ':full';

use Test::More tests => 4;
use t::lib::TestApp;

use Unicode::Normalize qw/NFD NFC NFKD NFKC/;
use Encode;
use Plack::Test;
use HTTP::Request::Common;

my $string = "\N{OHM SIGN}\N{GREEK CAPITAL LETTER OMEGA}\N{LATIN CAPITAL LETTER A}\N{COMBINING ACUTE ACCENT}\N{LATIN CAPITAL LETTER A WITH ACUTE}\N{LATIN SMALL LETTER LONG S WITH DOT ABOVE}\N{COMBINING DOT BELOW}";


test_psgi( t::lib::TestApp::dance, sub {
    my ($app) = @_;

    t::lib::TestApp::app->config->{'plugins'}->{'UnicodeNormalize'}->{'form'} = 'NFD';
    my $response = $app->(GET "/form/$string");
    is (decode('UTF-8', $response->content), NFD($string), "NFD form returned");

    t::lib::TestApp::app->config->{'plugins'}->{'UnicodeNormalize'}->{'form'} = 'NFC';
    $response = $app->(GET "/form/$string");
    is (decode('UTF-8', $response->content), NFC($string), "NFC form returned");

    t::lib::TestApp::app->config->{'plugins'}->{'UnicodeNormalize'}->{'form'} = 'NFKD';
    $response = $app->(GET "/form/$string");
    is (decode('UTF-8', $response->content), NFKD($string), "NFKD form returned");

    t::lib::TestApp::app->config->{'plugins'}->{'UnicodeNormalize'}->{'form'} = 'NFKC';
    $response = $app->(GET "/form/$string");
    is (decode('UTF-8', $response->content), NFKC($string), "NFKC form returned");

} );

