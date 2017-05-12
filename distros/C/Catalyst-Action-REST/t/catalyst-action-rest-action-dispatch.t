use strict;
use warnings;
use Test::More 0.88;
use FindBin;
use Data::Dumper;
use lib ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib" );
use Test::Rest;

# Should use the default serializer, YAML
my $t = Test::Rest->new( 'content_type' => 'text/plain' );

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';

foreach my $endpoint (qw/ test other_test /) {
    foreach my $method (qw(GET DELETE POST PUT OPTIONS)) {
        my $run_method = lc($method);
        my $res;
        if ( grep /$method/, qw(GET DELETE OPTIONS) ) {
            $res = request( $t->$run_method( url => '/actions/' . $endpoint ) );
        }
        else {
            $res = request(
                $t->$run_method(
                    url  => '/actions/' . $endpoint,
                    data => '',
                )
            );
        }
        ok( $res->is_success, "$method request succeeded" ) or warn Dumper($res);
        is(
            $res->content,
            "$method",
            "$method request had proper response"
        );
        is(
            $res->header('X-Was-In-TopLevel'),
            '1',
            "went through top level action for dispatching to $method"
        );
        is(
            $res->header('Using-Action'),
            'STATION',
            "went through action for dispatching to $method"
        );
    }
}

my $head_res = request(  $t->head(url => '/actions/test') );
ok($head_res->is_success, 'HEAD request succeeded')
    or diag($head_res->code);
ok(!$head_res->content, 'HEAD request had proper response');

my $res = request(
    $t->put(
        url  => '/actions/test',
        data => '',
    )
);
is(
    $res->header('Using-Action'),
    'STATION',
    "went through action for dispatching to PUT"
);
is(
    $res->header('Using-Sub-Action'),
    'MOO',
    "went through sub action for dispatching to PUT"
);

done_testing;
