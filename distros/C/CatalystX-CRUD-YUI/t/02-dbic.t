use Test::More tests => 8;

BEGIN {
    $ENV{CATALYST_DEBUG} ||= 0;
    use lib '../Rose-HTMLx-Form-Related/lib';
}

SKIP: {

    eval "use DBIx::Class";
    if ($@) {
        skip "install DBIx::Class to test MyDBIC app", 8;
    }
    eval "use DBIx::Class::RDBOHelpers";
    if ($@) {
        warn $@;
        skip "install DBIx::Class::RDBOHelpers to test MyDBIC app", 8;
    }
    eval "use CatalystX::CRUD::ModelAdapter::DBIC";
    if ( $@ or $CatalystX::CRUD::ModelAdapter::DBIC::VERSION < 0.08 ) {
        warn $@ if $@;
        skip
            "CatalystX::CRUD::ModelAdapter::DBIC 0.08 required to test MyRDBO app",
            8;
    }

    #check for sqlite3 cmd line tool
    my @sqlite_version = `sqlite3 -version`;
    if ( !@sqlite_version ) {
        skip "sqlite3 cmd line tool not found", 8;
    }

    use lib 't/MyDBIC/lib';

    # require to defer till skip checks
    require Catalyst::Test;
    Catalyst::Test->import('MyDBIC');

    use HTTP::Request::Common;
    use Data::Dump qw( dump );
    use JSON::XS;

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

    ok( $res = request(
            '/crud/test/foo/1/livegrid_related/foogoos?cxc-order=goo.id%20asc'
        ),
        "related table"
    );

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

}
