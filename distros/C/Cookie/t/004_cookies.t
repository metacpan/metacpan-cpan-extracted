#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    # 2021-11-01T08:12:10
    use Test::Time time => 1635754330;
    use HTTP::Request ();
    use HTTP::Response ();
    our $CRYPTX_REQUIRED_VERSION = '0.074';
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Cookie' );
    use_ok( 'Cookie::Jar' );
    require( "./t/env.pl" ) if( -e( "t/env.pl" ) );
};

subtest 'methods' => sub
{
    my $jar = Cookie::Jar->new;
    isa_ok( $jar, 'Cookie::Jar' );

    # To generate this list:
    # egrep -E '^sub ' ./lib/Cookie/Jar.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$jar, \"$m\" );"'
    can_ok( $jar, "init" );
    can_ok( $jar, "add" );
    can_ok( $jar, "add_cookie_header" );
    can_ok( $jar, "add_request_header" );
    can_ok( $jar, "add_response_header" );
    can_ok( $jar, "delete" );
    can_ok( $jar, "do" );
    can_ok( $jar, "exists" );
    can_ok( $jar, "extract" );
    can_ok( $jar, "extract_cookies" );
    can_ok( $jar, "fetch" );
    can_ok( $jar, "get" );
    can_ok( $jar, "get_by_domain" );
    can_ok( $jar, "host" );
    can_ok( $jar, "iv" );
    can_ok( $jar, "key" );
    can_ok( $jar, "load" );
    can_ok( $jar, "load_as_lwp" );
    can_ok( $jar, "load_as_netscape" );
    can_ok( $jar, "make" );
    can_ok( $jar, "merge" );
    can_ok( $jar, "parse" );
    can_ok( $jar, "purge" );
    can_ok( $jar, "repo" );
    can_ok( $jar, "request" );
    can_ok( $jar, "save" );
    can_ok( $jar, "save_as_lwp" );
    can_ok( $jar, "save_as_netscape" );
    can_ok( $jar, "scan" );
    can_ok( $jar, "set" );
};

subtest 'cookie parse' => sub
{
    my $longkey = 'x' x 1024;

    my @tests = (
        [
            'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' },
                { name => 'YYY', value => 0 },
                { name => 'YYY', value => 3 }
            ]
        ],
        [
            'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3;', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' },
                { name => 'YYY', value => 0 },
                { name => 'YYY', value => 3 },
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' },
                { name => 'YYY', value => 0 },
                { name => 'YYY', value => 3 },
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;   ', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' },
                { name => 'YYY', value => 0 },
                { name => 'YYY', value => 3 },
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' }
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY;', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' }
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY; ', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' }
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' },
                { name => 'YYY', value => "" }
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=;', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' },
                { name => 'YYY', value => "" }
            ]
        ],
        [
            'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=; ', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz' },
                { name => 'XXX', value => 'Foo Bar' },
                { name => 'YYY', value => "" }
            ]
        ],
        [
            "Foo=Bar; $longkey=Bar", [
                { name => 'Foo', value => 'Bar' },
                { name => $longkey, value => 'Bar' }
            ]
        ],
        [
            "Foo=Bar; $longkey=Bar; Bar=Baz", [
                { name => 'Foo', value => 'Bar' },
                { name => $longkey, value => 'Bar' },
                { name => 'Bar', value => 'Baz' }
            ]
        ],

        # from <https://github.com/plack/Plack/pull/564/files>
        [
            'ZZZ="spaced out"; XXX=Foo', [
                { name => 'ZZZ', value => 'spaced out' },
                { name => 'XXX', value => 'Foo' }
            ]
        ],
        [
            'ZZTOP=%22with%20quotes%22;', [
                { name => 'ZZTOP', value => '"with quotes"' }
            ]
        ],
        [
            'BOTH="%22internal quotes%22";', [
                { name => 'BOTH', value => '"internal quotes"'}
            ]
        ],
        [
            'EMPTYQUOTE="";', [
                { name => 'EMPTYQUOTE', value => '' }
            ]
        ],
        [
            'EMPTY=;', [
                { name => 'EMPTY', value => '' }
            ]
        ],
        [
            'BADSTART="data;', [
                { name => 'BADSTART', value => '"data' }
            ]
        ],
        [
            'BADEND=data";', [
                { name => 'BADEND', value => 'data"' }
            ]
        ],

        # disallow "," as a delimiter
        [
            'Foo=Bar; Bar=Baz,  XXX=Foo%20Bar   ; YYY=; ', [
                { name => 'Foo', value => 'Bar' },
                { name => 'Bar', value => 'Baz,  XXX=Foo Bar' },
                { name => 'YYY', value => "" }
            ]
        ], 

        [ '', [] ],
        [ undef, [] ],
    );

    my $jar = Cookie::Jar->new;
    foreach my $test ( @tests )
    {
        is_deeply( $jar->parse( $test->[0] ), $test->[1], $test->[0] );
    }
};

subtest 'cookie jar' => sub
{
    # For server repository
    my $srv = Cookie::Jar->new( debug => $DEBUG );
    # For client repository
    my $jar = Cookie::Jar->new( debug => $DEBUG );
    my $req = HTTP::Request->new( GET => 'https://www.example.com/' );
    $req->header( Host => 'www.example.com' );
    my $resp = HTTP::Response->new( 200 => 'OK' );
    $resp->request( $req );
    my $token = q{eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0};
    # For double authentication cookie scheme for example
    # See: <https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie>
    my $csrf = q{9849724969dbcffd48c074b894c8fbda14610dc0ae62fac0f78b2aa091216e0b.1635825594};
    my $rv;
    my $session_cookie = $srv->make( name => 'session_token' => value => $token, path => '/', expires => "Monday, 01-Nov-2021 17:12:40 GMT" ) ||
    do
    {
        diag( "Unable to create cookie session_token: ", $srv->error ) if( $DEBUG );
    };
    
    # $resp->header( 'Set-Cookie' => qq{session_token=${token}; path=/ ; expires=Monday, 01-Nov-2021 17:12:40 GMT} );
    $rv = $srv->set( $session_cookie, response => $resp ) || do
    {
        diag( "set returned an error: ", $srv->error ) if( $DEBUG );
    };
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    ok( $rv, 'add_request_header' );
    is( $req->header( 'Cookie' ), "session_token=$token" );
    
    $req = HTTP::Request->new( GET => 'https://www.example.com/' );
    $req->header( Host => 'www.example.com' );
    $resp = HTTP::Response->new( 200 => 'OK' );
    $resp->request( $req );
    my $csrf_cookie = $srv->make( name => 'csrf_token', value => $csrf, path => '/' ) || do
    {
        diag( "Unable to create cookie: ", $srv->error ) if( $DEBUG );
    };
    # $resp->header( 'Set-Cookie' => qq{csrf_token=${csrf}; path=/} );
    $rv = $srv->set( $csrf_cookie, response => $resp ) || do
    {
        diag( "set returned an error: ", $srv->error ) if( $DEBUG );
    };
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    
    $req = HTTP::Request->new( GET => 'https://www.example.com/foo/bar' );
    $req->header( Host => 'www.example.com' );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }

    $h = $req->header( 'Cookie' );
    like( $h, qr/session_token=${token}/ );
    like( $h, qr/csrf_token=${csrf}/ );
    
    $resp = HTTP::Response->new( 200 => 'OK' );
    $resp->request( $req );
    # $resp->header( 'Set-Cookie' => qq{site_prefs=lang%3Den-GB; path=/account} );
    my $prefs_cookie = $srv->make( name => 'site_prefs', value => "lang=en-GB", path => '/account' ) || do
    {
        diag( "Unable to add cookie site_prefs: ", $srv->error ) if( $DEBUG );
    };
    $rv = $srv->set( $prefs_cookie, response => $resp ) || do
    {
        diag( "set returned an error: ", $srv->error ) if( $DEBUG );
    };
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    
    $req = HTTP::Request->new( GET => 'https://www.example.com/' );
    $req->header( Host => 'www.example.com' );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    $h = $req->header( 'Cookie' );
    diag( "HTTP request is: ", $req->as_string ) if( $DEBUG );
    like( $h, qr/session_token=${token}/ );
    like( $h, qr/csrf_token=${csrf}/ );
    unlike( $h, qr/site_prefs=lang%3Den-GB/ );
    
    $req = HTTP::Request->new( GET => 'https://www.example.com/account/images/' );
    $req->header( Host => 'www.example.com' );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    $h = $req->header( 'Cookie' );
    diag( "HTTP request is: ", $req->as_string ) if( $DEBUG );
    like( $h, qr/session_token=${token}/ );
    like( $h, qr/csrf_token=${csrf}/ );
    like( $h, qr/site_prefs=lang%3Den-GB/ );
    
    # my $csrf_cookie = $jar->make( name => 'csrf_token', path => '/' )->elapse;
    $rv = $srv->fetch( request => $req ) || do
    {
        diag( "fetch returned an error: ", $srv->error ) if( $DEBUG );
    };
    $csrf_cookie = $srv->get( csrf_token => 'example.com' );
    ok( $csrf_cookie );
    $resp = HTTP::Response->new( 200 => 'OK' );
    SKIP:
    {
        if( !defined( $csrf_cookie ) )
        {
            skip( "Cannot find cookie \"csrf_cookie\".", 3 );
        }
        $csrf_cookie->elapse;
        diag( "Setting cookie csrf_token to expire: ", $csrf_cookie->as_string ) if( $DEBUG );
        # Set the Set-Cookie header fields
        $rv = $srv->set( $csrf_cookie, response => $resp ) || do
        {
            diag( "set returned an error: ", $srv->error ) if( $DEBUG );
        };
        diag( "Response header is now: ", $resp->as_string ) if( $DEBUG );
        $req = HTTP::Request->new( GET => 'https://www.example.com/account/' );
        $req->header( Host => 'www.example.com' );
        $resp->request( $req );
        # Extract them
        $rv = $jar->extract( $resp ) || do
        {
            diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
        };
        # Add them back to the client request object
        $rv = $jar->add_request_header( $req );
        if( !defined( $rv ) )
        {
            diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
        }
        $h = $req->header( 'Cookie' );
        like( $h, qr/session_token=${token}/ );
        # should not be here anymore
        unlike( $h, qr/csrf_token=${csrf}/ );
        like( $h, qr/site_prefs=lang%3Den-GB/ );
    };
};

subtest 'save and load' => sub
{
    my $jar = Cookie::Jar->new( debug => $DEBUG );
    $jar->add( name => 'cookie1', value => 'value1', path => '/', domain => 'example.com', secure => 1 );
    $jar->add( name => 'cookie2', value => 'value2', path => '/account', domain => 'api.example.com', secure => 1, http_only => 1 );
    $jar->add( name => 'cookie3', value => 'value3', path => '/', domain => 'img.example.com', secure => 1 );
    my $f = $jar->new_file( __FILE__ )->parent->child( 'cookies.json' );
    diag( "Saving to file '$f'" ) if( $DEBUG );
    SKIP:
    {
        $jar->save( $f ) || do
        {
            diag( "Unable to save to file \"$f\": ", $jar->error ) if( $DEBUG );
            skip( "Cannot save file", 9 );
        };
        ok( $f->size > 0, 'Saved json file size' );
        my $repo = Cookie::Jar->new( debug => $DEBUG );
        $repo->load( $f ) || do
        {
            diag( "Unable to load cookies from file \"$f\": ", $repo->error ) if( $DEBUG );
            skip( "Cannot load cookies", 8 );
        };
        ok( $repo->repo->size == $jar->repo->size, 'size' );
        diag( "Checking our cookie names '", $jar->repo->keys->sort->join( ',' ), "' vs the loaded repo ones '", $repo->repo->keys->sort->join( ',' ), "'." ) if( $DEBUG );
        ok( $repo->repo->keys->sort->join( ',' ) eq $jar->repo->keys->sort->join( ',' ), 'cookie names' );
        $jar->do(sub
        {
            my $c = shift( @_ );
            my $alter = $repo->get( $c->name => $c->domain );
            ok( $alter, "equivalent cookie" );
            if( !$alter )
            {
                skip( "Cannot find equivalent cookie \"" . $c->name . "\"", 1 );
            }
            ok( $c eq $alter, "cookie \"" . $c->name . "\" identical" );
        });
    };
    
    # Save as lwp and check
    my $jar2 = Cookie::Jar->new( debug => $DEBUG );
    my $f2 = $jar->new_file( __FILE__ )->parent->child( 'cookies.txt' );
    diag( "Saving to file '$f2'" ) if( $DEBUG );
    SKIP:
    {
        my $rv = $jar->save_as_lwp( $f2 ) || do
        {
            diag( "Unable to save to file \"$f2\": ", $jar->error ) if( $DEBUG );
            skip( "Cannot save file", 3 );
        };
        ok( $rv, 'save as lwp' );
        $jar2->load_as_lwp( $f2 ) || do
        {
            diag( "Unable to open lwp file \"$f2\": ", $jar2->error ) if( $DEBUG );
            skip( "Cannot open lwp cookie file.", 2 );
        };
        is( $jar2->repo->length, $jar->repo->length, 'lwp cookies total' );
        is( $jar2->repo->keys->sort->join( ',' )->scalar, $jar->repo->keys->sort->join( ',' )->scalar, 'lwp cookies keys' );
    };
};

done_testing();

__END__

