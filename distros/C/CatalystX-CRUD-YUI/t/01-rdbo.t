use strict;
use Test::More tests => 14;

BEGIN {
    $ENV{CATALYST_DEBUG} ||= 0;
    use lib '../Rose-HTMLx-Form-Related/lib';
}

SKIP: {

    eval "use Rose::DB::Object";
    if ($@) {
        skip "install Rose::DB::Object to test MyRDBO app", 14;
    }
    eval "use Rose::DBx::Object::MoreHelpers";
    if ($@) {
        skip "Rose::DBx::Object::MoreHelpers required to test MyRDBO app", 14;
    }
    eval "use CatalystX::CRUD::Model::RDBO";
    if ( $@ or $CatalystX::CRUD::Model::RDBO::VERSION < 0.14 ) {
        warn $@ if $@;
        skip "CatalystX::CRUD::Model::RDBO 0.14 required to test MyRDBO app",
            14;
    }

    #check for sqlite3 cmd line tool
    my @sqlite_version = `sqlite3 -version`;
    if ( !@sqlite_version ) {
        skip "sqlite3 cmd line tool not found", 14;
    }

    use lib 't/MyRDBO/lib';

    # require to defer till skip checks
    require Catalyst::Test;
    Catalyst::Test->import('MyRDBO');

    use HTTP::Request::Common;
    use Data::Dump qw( dump );
    use JSON::XS;

    #dump MyRDBO::Controller::CRUD::Test::Foo->config;

    ok( my $res = request('/crud/test/foo'), "response for /crud/test/foo" );

    #dump $res;

    is( $res->headers->{status}, '302', "redirect" );
    like( $res->headers->{location},
        qr{/crud/test/foo/count}, "redirect to count" );

    ok( $res = request('/crud/test/foo/1/view'), "view foo 1" );

    like(
        $res->content,
        qr/1972-03-29 06:30:00/,
        "view foo 1 contains correct ctime"
    );

    ok( $res = request('/crud/test/foo/1/livegrid_related/foogoos'),
        "related table" );

    #dump $res;

    ok( my $json = decode_json( $res->content ), "decode JSON" );

    #dump $json;

    is_deeply(
        $json,
        {   response => {
                value => {
                    dir   => "",
                    items => [
                        { id => 1, name => "blue" },
                        { id => 2, name => "orange" },
                    ],
                    limit       => 50,
                    offset      => "",
                    page        => 1,
                    "sort"      => "",
                    total_count => 2,
                    version     => 1,
                },
            },
        },
        "json response"
    );

    ok( my $chain_rest_test = request('/crud/test/foorest/1/chain_test'),
        "chain_rest_test" );
    is( $chain_rest_test->headers->{status}, 200, "chain test" );

    #dump $chain_rest_test;

    ok( my $create_form_test = request('/crud/test/foo/create'),
        "create action" );
    is( $create_form_test->headers->{status}, 200, "create action works" );

    #dump $create_form_test;

    # test 0.018 feature allowing edit of relationships when
    # parent object is can_write == 0
    ok( my $edit_no_write = request('/crud/test/foonowrite/1/edit'),
        "foonowrite test GET" );

    unlike( $edit_no_write->content, qr/<input id='cxc-save-button'/,
        "no action buttons in UI" );

    #dump $edit_no_write;

}
