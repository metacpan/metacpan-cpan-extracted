use strict;
use warnings;

use utf8;
use charnames ':full';

use Test::More tests => 6;
use t::lib::TestApp;

use Plack::Test;
use HTTP::Request::Common;

my $string1 = "\N{LATIN CAPITAL LETTER A}\N{COMBINING ACUTE ACCENT}";
my $string2 = "\N{LATIN CAPITAL LETTER A WITH ACUTE}";
isnt ($string1, $string2, "Initial conditions: strings are composed differently, are not equal");

test_psgi( t::lib::TestApp::dance, sub {
    my ($app) = @_;

    my $response = $app->( GET "/cmp/$string1/$string2" );
    is $response->content => 'eq', 'GET: Equality for differently composed strings using param';

    $response = $app->( GET "/cmp_route/$string1/$string2" );
    is $response->content => 'eq', 'GET: Equality for differently composed strings using route_parameters';

    $response = $app->( GET "/cmp_query?string1=$string1&string2=$string2" );
    is $response->content => 'eq', 'GET: Equality for differently composed strings using query_parameters';

    $response = $app->( POST '/cmp', [ string1 => $string1, string2 => $string2 ]);
    is $response->content => 'eq', 'POST: Equality for differently composed strings using param';

    $response = $app->( POST '/cmp_body', [ string1 => $string1, string2 => $string2 ]);
    is $response->content => 'eq', 'POST: Equality for differently composed strings using body_parameters';
} );

