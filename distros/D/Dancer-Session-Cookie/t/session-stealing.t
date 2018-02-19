#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 0.96 import => ["!pass"];
use File::Temp;
use HTTP::Date qw/str2time/;

use Plack::Test;
use HTTP::Cookies;
use HTTP::Request::Common;

my $tempdir = File::Temp->newdir;

my $app = Plack::Test->create( build_app() );

# Two different browsers
my @jars = map HTTP::Cookies->new, 1 .. 2;

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

# Set foo to one and two respectively
{
    mk_request( $app, $jars[0], '/?foo=one' );
    mk_request( $app, $jars[1], '/?foo=two' );
}

# Retrieve both stored 
{
    my $res = mk_request( $app, $jars[0], '/' );
    is( $res->content, 'one', 'Correct content' );
}

{
    my $res = mk_request( $app, $jars[1], '/' );
    is( $res->content, 'two', 'Correct content' );
}

{
    my $res = mk_request( $app, $jars[0], '/die', 0 );
    is( $res->code, 500, 'we died' );
}

{
    my $res = mk_request( $app, $jars[1], '/' );
    is( $res->content, 'two', 'Two received after first died' );
}

sub build_app {
    package MyApp;

    use Dancer ':tests', ':syntax';

    set apphandler          => 'PSGI';
    set appdir              => $tempdir;
    set access_log          => 0;           # quiet startup banner

    set session_cookie_key => "John has a long mustache";
    set session            => "cookie";
    set show_traces        => 1;
    set warnings           => 1;
    set show_errors        => 1;

    get '/die' => sub {
        die 'Bad route';
    };

    get '/' => sub {
        if (my $foo = param('foo')) {
            session(foo => $foo);
        }
        return session('foo');
    };

    dance;
}

done_testing;
