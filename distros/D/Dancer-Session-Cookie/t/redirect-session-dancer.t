#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => ["!pass"];

plan skip_all => "Plack::Test required" unless eval {
    require Plack::Test;
};

plan skip_all => "HTTP::Cookies required" unless eval {
    require HTTP::Cookies;
};

# available from Plack::Test
require HTTP::Request::Common;

sub mk_request {
    my ( $app, $jar, $url, $check_ok ) = @_;
    defined $check_ok or $check_ok = 1;
    my $req = HTTP::Request::Common::GET("http://localhost$url");
    $jar->add_cookie_header($req);
    my $res = $app->request($req);
    $jar->extract_cookies($res);
    $check_ok and ok( $res->is_success, "GET $url" );
    return $res;
}

my $app = Plack::Test->create( create_app() );
my $jar = HTTP::Cookies->new;
my $redir_url;

{
    my $res = mk_request( $app, $jar, '/xxx', 0 );
    ok( $res->is_redirect, 'GET /xxx redirects' );
    is(
        $res->header('Location'),
        'http://localhost/b',
        'Redirects to /b',
    );
}

{
    my $res = mk_request( $app, $jar, '/b' );
    is( $res->content, '/xxx', 'Correct content' );
}

sub create_app {
    package MyApp;
    use Dancer ':tests', ':syntax';

    set apphandler          => 'PSGI';
    set appdir              => '';          # quiet warnings not having an appdir
    set access_log          => 0;           # quiet startup banner

    set session_cookie_key  => "John has a long mustache";
    set session             => "cookie";

    get '/b' => sub {
        return session('abc');
    };

    hook 'before' => sub {
        my $a = request->path_info;
        if ( not request->path_info =~ m{^/(a|b|c)} ){
            session abc => $a ;
            return redirect '/b';
        }
    };

    dance;
}

done_testing;
