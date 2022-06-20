#!/usr/local/bin/perl
BEGIN
{
    use Test::More;
    use lib './lib';
    use constant HAS_APACHE_TEST => $ENV{HAS_APACHE_TEST};
    use constant HAS_SSL => $ENV{HAS_SSL};
    if( HAS_APACHE_TEST )
    {
        use_ok( 'Cookie::Jar' ) || BAIL_OUT( "Unable to load Cookie::Jar" );
        use_ok( 'Apache2::Const', qw( -compile :common :http ) ) || BAIL_OUT( "Unable to load Apache2::Const" );
        require_ok( 'Apache::Test' ) || BAIL_OUT( "Unable to load Apache::Test" );
        use_ok( 'Apache::TestUtil' ) || BAIL_OUT( "Unable to load Apache::TestUtil" );
        use_ok( 'Apache::TestRequest' ) || BAIL_OUT( "Unable to load Apache::TestRequest" );
        plan no_plan;
    }
    else
    {
        plan skip_all => 'Not running under modperl';
    }
    # 2021-11-1T167:12:10+0900
    use Test::Time time => 1635754330;
    our $CRYPTX_REQUIRED_VERSION = '0.074';
    our $DEBUG = exists( $ENV{COOKIES_DEBUG} ) ? $ENV{COOKIES_DEBUG} : exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    our( $hostport, $host, $port, $mp_host, $proto );
    require "t/env.pl";
};

BEGIN
{
    if( HAS_APACHE_TEST )
    {
        my $config = Apache::Test::config();
        $hostport = Apache::TestRequest::hostport( $config ) || '';
        ( $host, $port ) = split( ':', ( $hostport ) );
        $mp_host = 'www.example.org';
    }
    $proto = HAS_SSL ? 'https' : 'http';
    diag( "Host: '$host', port '$port'" ) if( $DEBUG );
};

subtest 'basic' => sub
{
    my $token = q{eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0};
    # For double authentication cookie scheme for example
    # See: <https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie>
    my $csrf = q{9849724969dbcffd48c074b894c8fbda14610dc0ae62fac0f78b2aa091216e0b.1635825594};
    my $jar = Cookie::Jar->new( debug => $DEBUG );
    my $ua = Apache::TestRequest->new;
    # To get the fingerprint for the certificate in ./t/server.crt, do:
    # echo "sha1\$$(openssl x509 -noout -in ./t/server.crt -fingerprint -sha1|perl -pE 's/^.*Fingerprint=|(\w{2})(?:\:?|$)/$1/g')"
    $ua->ssl_opts(
        # SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 
        # SSL_verify_mode => 0x00
        # verify_hostname => 0,
        SSL_fingerprint => 'sha1$DEE8650E44870896E821AAE4A5A24382174D100E',
        # SSL_version     => 'SSLv3',
        # SSL_verfifycn_name => 'localhost',
    );
    my $req = HTTP::Request->new( 'GET' => "${proto}://${hostport}/tests/test01" );
    $req->header( Host => "${mp_host}:${port}" );
    diag( "Request is: ", $req->as_string ) if( $DEBUG );
    my $resp = $ua->request( $req );
    diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
    is( $resp->code, Apache2::Const::HTTP_OK, 'test01 server' );
    
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    
    # test 2
    $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test02" );
    $req->header( Host => "${mp_host}:${port}" );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    ok( $rv, 'add_request_header' );
    is( $req->header( 'Cookie' ), "session_token=$token" );
    # Sending back the session cookie
    $resp = $ua->request( $req );
    diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
    is( $resp->code, Apache2::Const::HTTP_OK, 'test02 server' );
    
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    ok( $jar->exists( 'csrf_token' => $mp_host ), 'server cookie received' );
    
    # test 3
    $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test03" );
    $req->header( Host => "${mp_host}:${port}" );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }

    $h = $req->header( 'Cookie' );
    like( $h, qr/session_token=${token}/ );
    like( $h, qr/csrf_token=${csrf}/ );
    
    $resp = $ua->request( $req );
    diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
    is( $resp->code, Apache2::Const::HTTP_OK, 'test03 server' );
    
    # test 4
    $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test04" );
    $req->header( Host => "${mp_host}:${port}" );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    $resp = $ua->request( $req );
    diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    ok( $jar->exists( 'site_prefs' => $mp_host ), 'sites_prefs cookie received' );
    
    # test 5
    $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test05" );
    $req->header( Host => "${mp_host}:${port}" );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    $resp = $ua->request( $req );
    diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    is( $resp->code, Apache2::Const::HTTP_OK, 'server received only 2 cookies out of 3' );
    
    # test 6
    $req = HTTP::Request->new( GET => "${proto}://${hostport}/account/test06" );
    $req->header( Host => "${mp_host}:${port}" );
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    $resp = $ua->request( $req );
    diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
    $rv = $jar->extract( $resp ) || do
    {
        diag( "extract returned an error: ", $jar->error ) if( $DEBUG );
    };
    is( $resp->code, Apache2::Const::HTTP_OK, 'server received all 3 cookies' );
    my $csrf_cookie = $jar->get( 'csrf_token' => $mp_host );
    ok( $csrf_cookie, 'found csrf_token cookie' );
    SKIP:
    {
        if( !defined( $csrf_cookie ) )
        {
            skip( "csrf_token cookie not found", 1 );
        }
        ok( $csrf_cookie->is_expired, 'server has expired the csrf cookie' );
        if( $DEBUG && !$csrf_cookie->is_expired )
        {
            diag( "csrf_token cookie is not expired, but it should be. Its expiration timestamp is: '", $csrf_cookie->expires, "' (", overload::StrVal( $csrf_cookie->expires ), ") and its is_expired method returned '", $csrf_cookie->is_expired, "'" );
        }
    };
    
    $req = HTTP::Request->new( GET => "${proto}://${hostport}/account/" );
    $req->header( Host => "${mp_host}:${port}" );
    # Add them back to the client request object
    $rv = $jar->add_request_header( $req );
    if( !defined( $rv ) )
    {
        diag( "add_request_header returned an error: ", $jar->error ) if( $DEBUG );
    }
    $h = $req->header( 'Cookie' );
    like( $h, qr/session_token=${token}/ );
    # should not be here anymore, because we acknowledged it expired
    unlike( $h, qr/csrf_token=${csrf}/ );
    like( $h, qr/site_prefs=lang%3Den-GB/ );
};

subtest 'encrypted' => sub
{
    SKIP:
    {
        eval( "use Crypt::Cipher ${CRYPTX_REQUIRED_VERSION}" );
        if( $@ )
        {
            skip( "Crypt::Cipher is not installed on your system", 4 );
        }
        my $jar = Cookie::Jar->new( debug => $DEBUG );
        my $ua = Apache::TestRequest->new( cookie_jar => $jar );
        $ua->ssl_opts(
            SSL_fingerprint => 'sha1$DEE8650E44870896E821AAE4A5A24382174D100E',
        );
        
        # test 1
        $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test07" );
        $req->header( Host => "${mp_host}:${port}" );
        diag( "Request is: ", $req->as_string ) if( $DEBUG );
        $resp = $ua->request( $req );
        diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
        is( $resp->code, Apache2::Const::HTTP_OK, 'server issued secret cookies' );
        my $c = $jar->get( 'secret_cookie' );
        ok( $c, 'found secret cookie in our repository' );
        if( !defined( $c ) )
        {
            skip( "Cookie secret_cookie not found.", 2 );
        }
        diag( "Secret cookie value is: '", $c->value, "'." ) if( $DEBUG );
        
        # test 2
        # Returning the secret cookie for check
        $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test08" );
        $req->header( Host => "${mp_host}:${port}" );
        diag( "Request is: ", $req->as_string ) if( $DEBUG );
        $resp = $ua->request( $req );
        diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
        is( $resp->code, Apache2::Const::HTTP_OK, 'server received valid encrypted cookie' );
        
        # test 3
        # Altering the secret cookie should yield a failed check
        my $encrypted_val = $c->value;
        # trim it by 1 character to alter its value
        $c->value( $encrypted_val->substr(1) );
        $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test09" );
        $req->header( Host => "${mp_host}:${port}" );
        diag( "Request is: ", $req->as_string ) if( $DEBUG );
        $resp = $ua->request( $req );
        diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
        is( $resp->code, Apache2::Const::HTTP_OK, 'server failed to decrypt the modified value' );
    };
};

subtest 'signed' => sub
{
    SKIP:
    {
        eval( "use Crypt::Cipher ${CRYPTX_REQUIRED_VERSION}" );
        if( $@ )
        {
            skip( "Crypt::Cipher is not installed on your system", 4 );
        }
        my $jar = Cookie::Jar->new( debug => $DEBUG );
        my $ua = Apache::TestRequest->new( cookie_jar => $jar );
        $ua->ssl_opts(
            SSL_fingerprint => 'sha1$DEE8650E44870896E821AAE4A5A24382174D100E',
        );
        
        # test 1
        $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test10" );
        $req->header( Host => "${mp_host}:${port}" );
        diag( "Request is: ", $req->as_string ) if( $DEBUG );
        $resp = $ua->request( $req );
        diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
        is( $resp->code, Apache2::Const::HTTP_OK, 'server issued a signed cookie' );
        my $c = $jar->get( 'signed_cookie' );
        ok( $c, 'found signed cookie in our repository' );
        if( !defined( $c ) )
        {
            skip( "Cannot find signed cookie \"signed_cookie\"", 2 );
        }
        
        diag( "Signed cookie value is: '", $c->value, "'." ) if( $DEBUG );
        
        # test 2
        # Returning the signed cookie for check
        $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test11" );
        $req->header( Host => "${mp_host}:${port}" );
        diag( "Request is: ", $req->as_string ) if( $DEBUG );
        $resp = $ua->request( $req );
        diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
        is( $resp->code, Apache2::Const::HTTP_OK, 'server received valid signed cookie' );
        
        # test 3
        # Altering the signed cookie should yield a failed check
        my $encrypted_val = $c->value;
        # trim it by 1 character to alter its value
        $c->value( $encrypted_val->substr(1) );
        $req = HTTP::Request->new( GET => "${proto}://${hostport}/tests/test12" );
        $req->header( Host => "${mp_host}:${port}" );
        diag( "Request is: ", $req->as_string ) if( $DEBUG );
        $resp = $ua->request( $req );
        diag( "Server response is: ", $resp->as_string ) if( $DEBUG );
        is( $resp->code, Apache2::Const::HTTP_OK, 'server failed to validate the modified value' );
    };
};

done_testing();

__END__

