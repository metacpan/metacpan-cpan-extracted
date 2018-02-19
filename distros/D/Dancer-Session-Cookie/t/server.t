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

sub find_cookie {
  my ($res, $name) = @_;
  $name ||= 'dancer.session';
  my @cookies = $res->header('set-cookie');
  for my $c (@cookies) {
    next unless $c =~ /\Q$name\E/;
    return $c;
  }
  return;
}

sub extract_cookie {
  my ($res, $name) = @_;
  my $c = find_cookie($res, $name) or return;
  my @parts = split /;\s+/, $c;
  my %hash =
    map { my ( $k, $v ) = split /\s*=\s*/; $v ||= 1; ( lc($k), $v ) } @parts;
  $hash{expires} = str2time( $hash{expires} )
    if $hash{expires};
  return \%hash;
}

my @configs = (
    {
        label => 'default config',
        settings => {},
    },
    {
        label => 'alternate name',
        settings => {
            session_name => "my_app_session",
        },
    },
    {
        label => 'expires 300',
        settings => {
            session_expires => 300,
            session_name => undef,
        },
    },
    {
        label => 'expires +1h',
        settings => {
            session_expires => "1 hour",
        },
    },
);

my $url = 'http://localhost';
MAIN:
for my $config ( @configs ) {
    my $app = Plack::Test->create( create_app( $config ) );

    subtest $config->{label} => sub {
        # Simulate two different browsers with two different jars
        my @jars = map HTTP::Cookies->new, 1 .. 2;

        for my $jar (@jars) {
            subtest 'one browser' => sub {
                {
                    my $req = HTTP::Request::Common::GET("$url/foo");
                    my $res = $app->request($req);
                    $jar->extract_cookies($res);
                    ok( $res->is_success, 'GET /foo' );
                    is(
                        $res->content,
                        'hits: 0, last_hit: ',
                        'Got content',
                    );
                }

                ok( $jar->as_string, 'session cookie set' );

                {
                    my $req = HTTP::Request::Common::GET("$url/bar");
                    $jar->add_cookie_header($req);
                    my $res = $app->request($req);
                    ok( $res->is_success, 'GET /bar' );
                    $jar->extract_cookies($res);
                    is(
                        $res->content,
                        "hits: 1, last_hit: foo",
                        'Got content',
                    );
                }

                {
                    my $req = HTTP::Request::Common::GET("$url/forward");
                    $jar->add_cookie_header($req);
                    my $res = $app->request($req);
                    $jar->extract_cookies($res);
                    ok( $res->is_success, 'GET /forward' );
                    is(
                        $res->content,
                        "hits: 2, last_hit: bar",
                        "session not overwritten",
                    );
                }

                {
                    my $req = HTTP::Request::Common::GET("$url/baz");
                    $jar->add_cookie_header($req);
                    my $res = $app->request($req);
                    $jar->extract_cookies($res);
                    ok( $res->is_success, 'GET /baz' );
                    is(
                        $res->content,
                        "hits: 3, last_hit: whatever",
                        'Got content',
                    );
                }
            };
        };

        {
            my $req = HTTP::Request::Common::GET("$url/wibble");
            $jars[0]->add_cookie_header($req);
            my $res = $app->request($req);
            $jars[0]->extract_cookies($res);
            ok( $res->is_success, 'GET /wibble' );
            is(
                $res->content,
                "hits: 4, last_hit: baz",
                "session not overwritten",
            );
        }

        my $redir_url;
        {
            my $req = HTTP::Request::Common::GET("$url/clear");
            $jars[0]->add_cookie_header($req);
            my $res = $app->request($req);
            $jars[0]->extract_cookies($res);
            ok( $res->is_redirect, 'GET /clear' );
            is(
                $redir_url = $res->header('Location'),
                'http://localhost/postclear',
                'Redirects to /postclear',
            );
        }

        {
            my $req = HTTP::Request::Common::GET($redir_url);
            $jars[0]->add_cookie_header($req);
            my $res = $app->request($req);
            $jars[0]->extract_cookies($res);
            ok( $res->is_success, "GET $redir_url" );
            is(
                $res->content,
                "hits: 0, last_hit: ",
                "session destroyed",
            );
        }
    };
}


sub create_app {
    my $config = shift;

    use Dancer ':tests', ':syntax';

    set apphandler          => 'PSGI';
    set appdir              => $tempdir;
    set access_log          => 0;           # quiet startup banner

    set session_cookie_key  => "John has a long mustache";
    set session             => "cookie";
    set show_traces => 1;
    set warnings => 1;
    set show_errors => 1;

    set %{$config->{settings}} if %{$config->{settings}};

    get "/clear" => sub {
        session "useless" =>  1; # force write/flush
        session->destroy;
        redirect '/postclear';
    };

    get "/forward" => sub {
        session ignore_me => 1;
        forward '/whatever';
    };

    get "/*" => sub {
        my $hits = session("hit_counter") || 0;
        my $last = session("last_hit") || '';

        session hit_counter => $hits + 1;
        session last_hit => (splat)[0];

        return "hits: $hits, last_hit: $last";
    };

    dance;
}

done_testing;
