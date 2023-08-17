#!/usr/local/bin/perl
BEGIN
{
    use Test::More;
    use lib './lib';
    use vars qw( $DEBUG $VERSION $hostport $host $port $mp_host $proto $ua @ua_args );
    use constant HAS_APACHE_TEST => $ENV{HAS_APACHE_TEST};
    use constant HAS_SSL => $ENV{HAS_SSL};
    if( HAS_APACHE_TEST )
    {
        use_ok( 'Apache2::API' ) || BAIL_OUT( "Unable to load Apache2::API" );
        use_ok( 'Apache2::Const', qw( -compile :common :http ) ) || BAIL_OUT( "Unable to load Apache2::Const" );
        require_ok( 'Apache::Test' ) || BAIL_OUT( "Unable to load Apache::Test" );
        use_ok( 'Apache::TestUtil' ) || BAIL_OUT( "Unable to load Apache::TestUtil" );
        use_ok( 'Apache::TestRequest' ) || BAIL_OUT( "Unable to load Apache::TestRequest" );
        use_ok( 'HTTP::Request' ) || BAIL_OUT( "Unable to load HTTP::Request" );
        use_ok( 'JSON' ) || BAIL_OUT( "Unable to load JSON" );
        plan no_plan;
    }
    else
    {
        plan skip_all => 'Not running under modperl';
    }
    use Module::Generic::File qw( file );
    # 2021-11-1T167:12:10+0900
    use Test::Time time => 1635754330;
    use URI;
    our $DEBUG = exists( $ENV{API_DEBUG} ) ? $ENV{API_DEBUG} : exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    our $VERSION = 'v0.1.0';
    our( $hostport, $host, $port, $mp_host, $proto, $ua );
    require( "./t/env.pl" ) if( -e( "t/env.pl" ) );
};

BEGIN
{
    if( HAS_APACHE_TEST )
    {
        my $config = Apache::Test::config();
        $hostport = Apache::TestRequest::hostport( $config ) || '';
        ( $host, $port ) = split( ':', ( $hostport ) );
        $mp_host = 'www.example.org';
        our @ua_args = (
            agent           => 'Test-Apache2-API/' . $VERSION,
            cookie_jar      => {},
            default_headers => HTTP::Headers->new(
                Host            => "${mp_host}:${port}",
                Accept          => 'application/json; version=1.0; charset=utf-8, text/javascript, */*',
                Accept_Encoding => 'gzip, deflate, br',
                Accept_Language => 'en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2',
            ),
            keep_alive      => 1,
        );
        Apache::TestRequest::user_agent( @ua_args, reset => 1 );
        $ua = Apache::TestRequest->new( @ua_args );
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
    }
    $proto = HAS_SSL ? 'https' : 'http';
    diag( "Host: '$host', port '$port'" ) if( $DEBUG );
};

use strict;
use warnings;
our $config = Apache::TestConfig->thaw->httpd_config;
die( "No directory \"t/logs\"" ) if( !$config->{vars}->{t_logs} || !-e( $config->{vars}->{t_logs} ) );
our $logs_dir = file( $config->{vars}->{t_logs} );
our $target2path = 
{
api => $logs_dir->child( 'apache2/api' ),
request => $logs_dir->child( 'apache2/api/request' ),
response => $logs_dir->child( 'apache2/api/response' ),
};

my $jwt = q{eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0};

subtest 'core' => sub
{
    my( $req, $resp );
    &simple_test({ target => 'api', name => 'compression_threshold', code => Apache2::Const::HTTP_OK });

    &simple_test({ target => 'api', name => 'decode_json', code => Apache2::Const::HTTP_OK });

    &simple_test({ target => 'api', name => 'encode_decode_url', code => Apache2::Const::HTTP_OK });

    &simple_test({ target => 'api', name => 'auth', code => Apache2::Const::HTTP_OK, headers => [Authorization => "Bearer: $jwt"] });

    &simple_test({ target => 'api', name => 'header_datetime', code => Apache2::Const::HTTP_OK });

    &simple_test({ target => 'api', name => 'is_perl_option_enabled', code => Apache2::Const::HTTP_OK });

    &simple_test({ target => 'api', name => 'json', code => Apache2::Const::HTTP_OK });
    
    $resp = &make_request( api => 'reply' );
    my $j = JSON->new;
    my $content = $resp->decoded_content;
    diag( "test 'reply' decoded_content is '$content'" ) if( $DEBUG );
    my $ref;
    eval
    {
        $ref = $j->decode( $content );
    };
    
    ok( ref( $ref ) eq 'HASH', 'reply -> JSON decoded content is an hash reference' );
    is( $resp->code, Apache2::Const::HTTP_OK, 'reply code' );
    is( $ref->{message}, 'ok', 'reply message' );

    &simple_test({ target => 'api', name => 'server', code => Apache2::Const::HTTP_OK });

    &simple_test({ target => 'api', name => 'server_version', code => Apache2::Const::HTTP_OK });
};

subtest 'request' => sub
{
    my @tests = qw(
        aborted accept accept_charset accept_encoding accept_language accept_type 
        accept_version acceptable acceptables allowed as_string auto_header
        charset client_api_version connection decode encode document_root
        document_uri env finfo gateway_interface global_request has_auth header_only 
        headers headers_as_hashref headers_as_json headers_in is_secure json local_addr
        method mod_perl_version no_cache notes path_info 
        preferred_language protocol remote_addr request_time server
        socket subprocess_env the_request time2str type uri user_agent 
    );
    
    foreach my $test ( @tests )
    {
        &simple_test({ target => 'request', name => $test, code => Apache2::Const::HTTP_OK });
    }
    
    my( $req, $resp );
    &simple_test({ target => 'request', name => 'args', code => Apache2::Const::HTTP_OK, query => 'foo=1&foo=2&bar=3&lang=ja_JP' });

    &simple_test({ target => 'request', name => 'auth', code => Apache2::Const::HTTP_OK, headers => [Authorization => "Bearer: $jwt"] });

    &simple_test({ target => 'request', name => 'body', code => Apache2::Const::HTTP_OK, headers => [Content_Type => "application/x-www-form-urlencoded"], body => q{a=a1&b=b1&b=b2&c=foo+&tengu=%E5%A4%A9%E7%8B%97}, http_method => 'post' });

    &simple_test({ target => 'request', name => 'cookie', code => Apache2::Const::HTTP_OK, headers => [Cookie => "my_session=foo"] });

my $data_body = <<EOT;
{
    "id": 123,
    "client_id": "37c58138-e259-44aa-9eee-baf3cbecca75"
}
EOT
    &simple_test({ target => 'request', name => 'data', code => Apache2::Const::HTTP_OK, headers => [Content_Type => 'application/json; charset=utf-8'], body => $data_body, http_method => 'post' });

    &simple_test({ target => 'request', name => 'param', code => Apache2::Const::HTTP_OK, query => 'foo=bar&lang=ja_JP' });

    &simple_test({ target => 'request', name => 'params', code => Apache2::Const::HTTP_OK, query => 'foo=bar&lang=ja_JP' });

    &simple_test({ target => 'request', name => 'payload', code => Apache2::Const::HTTP_OK, headers => [Content_Type => 'application/json; charset=utf-8'], body => $data_body, http_method => 'post' });

    &simple_test({ target => 'request', name => 'query', code => Apache2::Const::HTTP_OK, query => 'foo=1&bar=3&lang=ja_JP' });

    # 最高だ！
    &simple_test({ target => 'request', name => 'query_string', code => Apache2::Const::HTTP_OK, query => 'foo=bar&lang=ja-JP&q=%E6%9C%80%E9%AB%98%E3%81%A0%EF%BC%81' });

    &simple_test({ target => 'request', name => 'referer', code => Apache2::Const::HTTP_OK, headers => [Referer => 'https://example.org/some/where.html'] });
};

subtest 'response' => sub
{
    my @tests = qw(
        headers headers_out make_etag no_cache no_local_copy sendfile set_last_modified
        socket 
    );
    
    foreach my $test ( @tests )
    {
        &simple_test({ target => 'response', name => $test, code => Apache2::Const::HTTP_OK });
    }
};

sub make_request
{
    my( $type, $path, $opts ) = @_;
    
    my $http_meth = uc( $opts->{http_method} // 'GET' );
    my $req = HTTP::Request->new( $http_meth => "${proto}://${hostport}/tests/${type}/${path}",
        ( exists( $opts->{headers} ) ? $opts->{headers} : () ),
        ( ( exists( $opts->{body} ) && length( $opts->{body} // '' ) ) ? $opts->{body} : () ),
    );
    if( $opts->{query} )
    {
        my $u = URI->new( $req->uri );
        $u->query( $opts->{query} );
        $req->uri( $u );
    }
    
    unless( $req->header( 'Content-Type' ) )
    {
        $req->header( Content_Type => 'text/plain; charset=utf-8' );
    }
    
    # $req->header( Host => "${mp_host}:${port}" );
    diag( "Request for $path is: ", $req->as_string ) if( $DEBUG );
    my $resp = $ua->request( $req );
    diag( "Server response for $path is: ", $resp->as_string ) if( $DEBUG );
    return( $resp );
}

sub simple_test
{
    my $opts = shift( @_ );
    if( !$opts->{name} )
    {
        die( "No test name was provided." );
    }
    elsif( !defined( $opts->{code} ) )
    {
        die( "No HTTP code was provided." );
    }
    elsif( !defined( $opts->{target} ) )
    {
        die( "No test target was provided. It should be 'api', 'request' or 'response'" );
    }
    my $resp = &make_request( $opts->{target} => $opts->{name}, $opts );
    is( $opts->{code}, Apache2::Const::HTTP_OK, $opts->{name} ) || 
        diag( "Error with test \"$opts->{name}\". See log content below:\n", &get_log( $opts ) );
}

sub get_log
{
    my $opts = shift( @_ );
    my $log_file = $target2path->{ $opts->{target} }->child( $opts->{name} . '.log' );
    if( $log_file->exists )
    {
        return( $log_file->load_utf8 );
    }
    else
    {
        diag( "Test $opts->{target} -> $opts->{name} seems to have failed, but there is no log file \"$log_file\"" ); 
    }
}

done_testing();

__END__

