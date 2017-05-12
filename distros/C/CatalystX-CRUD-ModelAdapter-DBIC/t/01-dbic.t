#!/usr/bin/env perl
use strict;

use Test::More tests => 23;

BEGIN {
    use lib qw( ../../CatalystX-CRUD/trunk/lib t );
    use lib qw( t/lib );
    $ENV{CATALYST_DEBUG} ||= 0;
}

END { unlink('t/example.db') unless $ENV{PERL_DEBUG}; }

SKIP: {

    use_ok('CatalystX::CRUD::ModelAdapter::DBIC');

    #check for sqlite3 cmd line tool
    my @sqlite_version = `sqlite3 -version`;
    if ( !@sqlite_version ) {
        skip "sqlite3 cmd line tool not found", 22;
    }

    system("cd t/ && $^X insertdb.pl") and die "can't create db: $!";

    require Catalyst::Test;
    Catalyst::Test->import('MyApp');
    use Data::Dump qw( dump );
    use HTTP::Request::Common;

    ok( my $res = request('/test1'), "get /test1" );
    is( $res->content, 13, "right number of results" );
    ok( $res = request('/crud/test2?cd.title=Bad'), "get /test2" );
    is( $res->content, 3, "iterator for cd.title=Bad" );
    ok( $res = request('/crud/test3?cd.title=Bad'), "get /test3" );
    is( $res->content, 3, "search for cd.title=Bad" );
    ok( $res = request('/crud/test4?cd.title=Bad'), "get /test4" );
    is( $res->content, 3, "count for cd.title=Bad" );

    # read
    ok( $res = request( HTTP::Request->new( GET => '/crud/1/view' ) ),
        "GET view" );

    #diag( $res->content );
    is_deeply(
        eval $res->content,
        { title => "Beat It", trackid => 1 },
        "GET track 1"
    );

    # create
    ok( $res = request(
            POST(
                '/crud/0/save',
                [   title   => 'Something New, Something Blue',
                    trackid => 8
                ]
            )
        ),
        "POST new track"
    );

    #diag( $res->content );
    is_deeply(
        eval $res->content,
        { title => "Something New, Something Blue", trackid => 8 },
        "POST new track"
    );

    # GET new track
    ok( $res = request('/crud/8/view'), "get /crud/8/view" );
    is_deeply(
        eval $res->content,
        { title => "Something New, Something Blue", trackid => 8 },
        "GET new track"
    );

    # multiple column search
    ok( $res = request(
            POST(
                '/crud/search',
                [   'cxc-query' => qq/me.trackid=7/,
                    'cxc-order' => 'me.trackid ASC me.title DESC',
                ]
            )
        ),
        'multi-column sort POST'
    );

    #warn $res->content;

    is_deeply(
        eval $res->content,
        { title => "The Way I Am", trackid => 7 },
        'multi-column sort'
    );

    # fuzzy search
    ok( $res = request(
            POST(
                '/crud/search',
                [   'me.title'   => qq/"way i" nowayimatchanything/,
                    'cxc-fuzzy2' => 1,
                    'cxc-order'  => 'me.trackid ASC me.title DESC',
                    'cxc-op'     => 'OR',
                ]
            )
        ),
        'fuzzy search'
    );

    #warn $res->content;

    is_deeply(
        eval $res->content,
        { title => "The Way I Am", trackid => 7 },
        'fuzzy search'
    );

    # test *_related features

    ok( $res = request(
            POST( '/crud/3/cds/1/add', [] ), "/crud/3/tracks/1/add"
        ),
        "add track to cd"
    );

    is( $res->headers->{status}, 204, "POST returned OK" );

    #dump $res;

    ok( $res = request(
            POST( '/crud/3/cds/1/remove', [] ),
            "/crud/3/tracks/1/remove"
        ),
        "remove track from cd"
    );

    is( $res->headers->{status}, 204, "POST returned OK" );

    #dump $res;

}    # end SKIP
