use strict;
use warnings;

use Test::More;
use Plack::Test;

BEGIN {
    
    use Dancer2;
    
    set session => undef; # explicit
    set plugins => {
        'HTTP::Auth::Extensible' => {
            default_realm => "realm_one",
            realms => {
                realm_one => {
                    scheme => "Basic",
                    provider => "Config",
                    users => [
                      { user => "dave",
                        pass => "beer",
                        name => "David Precious",
                        roles => [ 'BeerDrinker', 'Motorcyclist' ],
                      },
                      { user => "bob",
                        pass => "cider",
                        name => "Bob Smith",
                        roles => [ 'Ciderdrinker' ],
                      },
                    ]
                },
                realm_two => {
                    scheme => "Basic",
                    provider => "Config",
                    users => [
                     { user => "burt",
                       pass => "bacharach",
                     },
                     { user => "hashedpassword",
                       pass => "{SSHA}+2u1HpOU7ak6iBR6JlpICpAUvSpA/zBM",
                     },
                   ]
                }
            }
        }
    };
    set logger      => "file";
#   set log         => "core";
    set show_errors => 1;
    set serializer  => "YAML";
    
    use Dancer2::Plugin::HTTP::Auth::Extensible;
    no warnings 'uninitialized';
    
    get '/realm_one' => http_requires_authentication 'realm_one' => sub {
        "Welcome to realm_one"
    };
    
    get '/realm_two' => http_requires_authentication 'realm_two' => sub {
        "Welcome to realm_two"
    };
    
    get '/realm_bad' => http_requires_authentication 'realm_bad' => sub {
        "Welcome to realm_bad" # we are not suposed to get here
    };
    
    get '/realm'     => http_requires_authentication                sub {
        "Welcome to realm_one, the default"
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
    my $req = HTTP::Request->new( GET => '/realm');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        'Status 401: Unauthorized for realm_one, the default'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="realm_one"',
        'HTTP-field: WWW-Authentication for realm_one, the default'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/realm_one');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        'Status 401: Unauthorized for realm_one'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="realm_one"',
        'HTTP-field: WWW-Authentication for realm_one'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/realm_two');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        'Status 401: Unauthorized for realm_two'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        'Basic realm="realm_two"',
        'HTTP-field: WWW-Authentication for realm_two'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/realm_bad');
    my $res = $cb->( $req );
    is (
        $res->code,
        500,
        'Status 500: realm does not exist'
    );
    like (
        $res->content,
        qr{required realm does not exist: 'realm_bad'},
        'Prompt 500: realm does not exist'
    );
};

done_testing();
