use strict;
use warnings;
use Test::More;
use FindBin;

use lib ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib" );
use Test::Rest;

my $t = Test::Rest->new( 'content_type' => 'text/plain' );

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';

my $url = '/actionsforbrowsers/for_browsers';

foreach my $method (qw(GET POST)) {
    my $run_method = lc($method);
    my $result     = "something $method";
    my $res;
    if ( $method eq 'GET' ) {
        $res = request( $t->$run_method( url => $url ) );
    } else {
        $res = request(
            $t->$run_method(
                url  => $url,
                data => '',
            )
        );
    }
    ok( $res->is_success, "$method request succeeded" );
    is(
        $res->content,
        "$method",
        "$method request had proper response"
    );
}

my $res = request(
    $t->get(
        url     => $url,
        headers => { Accept => 'text/html' },
    )
);

ok( $res->is_success, "GET request succeeded (client looks like browser)" );
is(
    $res->content,
    "GET_html",
    "GET request had proper response (client looks like browser)"
);

done_testing;

