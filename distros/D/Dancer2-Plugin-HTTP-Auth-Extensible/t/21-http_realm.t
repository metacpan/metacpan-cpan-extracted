use strict;
use warnings;

use Test::More;
use Plack::Test;

BEGIN {
    
    use Dancer2;
    
    set session => undef; # explicit
    set plugins => {
        'HTTP::Auth::Extensible' => {
            realms => {
                some_realm => {
                    scheme => "Basic",
                    provider => "Config",
                    users => [
                      { user => "dave",
                        pass => "beer",
                        name => "David Precious",
                        roles => [
                            'BeerDrinker',
                            'VodkaDrinker',
                        ],
                      },
                    ]
                }
            }
        }
    };
    set logger      => "file";
    set log         => "core";
    set show_errors => 1;
    set serializer  => "YAML";
    
    use Dancer2::Plugin::HTTP::Auth::Extensible;
    no warnings 'uninitialized';

    get '/auth_http_realm' => http_requires_authentication sub {
        my $variable = http_realm;
        return qq|variable got: <undef>| unless defined $variable;
        return qq|variable got: '$variable'|;
    };
    
    get '/http_realm' => sub {
        my $variable = http_realm;
        return qq|variable got: <undef>| unless defined $variable;
        return qq|variable got: '$variable'|;
    };
    
    put '/auth_http_realm' => http_requires_authentication sub {
        http_realm(params->{new});
        my $variable = http_realm;
        return qq|variable set: <undef>| unless defined $variable;
        return qq|variable set: '$variable'|;
    };

    put '/http_realm' => sub {
        http_realm(params->{new});
        my $variable = http_realm;
        return qq|variable set: <undef>| unless defined $variable;
        return qq|variable set: '$variable'|;
    };

} # BEGIN

my $app = Dancer2->runner->psgi_app;

{
    is (
        ref $app,
        'CODE',
        'Got app'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth_http_realm');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    like (
        $res->content,
        qr|variable got: '.*'|,
        'get http_realm authenticated'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/http_realm');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    like (
        $res->content,
        qr|variable got: <undef>|,
        'get http_realm'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( PUT => '/auth_http_realm');
    $req->authorization_basic ( 'dave', 'beer');
    $req->uri->query_form( new => 'NEW');
    my $res = $cb->( $req );
    like (
        $res->content,
        qr|variable set: 'NEW'|,
        'put http_realm authenticated'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( PUT => '/http_realm');
    $req->authorization_basic ( 'dave', 'beer');
    $req->uri->query_form( new => 'NEW');
    my $res = $cb->( $req );
    like (
        $res->content,
        qr|variable set: 'NEW'|,
        'put http_realm'
    );
};

done_testing();
