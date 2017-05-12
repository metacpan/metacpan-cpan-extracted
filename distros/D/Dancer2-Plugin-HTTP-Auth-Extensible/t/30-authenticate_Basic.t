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
#   set log         => "core";
    set show_errors => 1;
#   set serializer  => "YAML"; # output format added '---'
    
    use Dancer2::Plugin::HTTP::Auth::Extensible;
    no warnings 'uninitialized';

    get '/' => sub { "Access does not need any authorization" };
    
    get '/auth' => http_requires_authentication sub {
        "Access granted for default realm"
    };

    get '/beer'     => http_requires_role 'BeerDrinker' => sub {
        "Enjoy your Beer!"
    };

    get '/vodka'    => http_requires_role 'VodkaDrinker' => sub {
        "Enjoy your Vodka!"
    };

    get '/martini'  => http_requires_role 'MartiniDrinker' => sub {
        "Enjoy your Martini!"
    };

    get '/juice'   => http_requires_role 'JuiceDrinker' => sub {
        "Enjoy your Juice!"
    };

    get '/drinker'  => http_requires_role qr{Drinker$} => sub {
        "Enjoy your bevarage!"
    };

    get '/thirsty'  => http_requires_any_role  [ 'BeerDrinker', 'JuiceDrinker' ] => sub {
        "Enjoy your drinks, one at a time!"
    };

    get '/alcohol'  => http_requires_all_roles [ 'BeerDrinker', 'VodkaDrinker' ] => sub {
        "Enjoy your alcohol, but don't drink too much!"
    };

    get '/cocktail' => http_requires_all_roles [ 'VodkaDrinker', 'MartiniDrinker' ] => sub {
        "Stirred, not shaken!"
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
    my $req = HTTP::Request->new( GET => '/');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        'Status 200: root resource accessible without login'
    );
    is (
        $res->content,
        qq|Access does not need any authorization|,
        'Delivering: root resource accessible without login'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        'Status 401: without HTTP-field Autorization'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        qq|Basic realm="some_realm"|,
        'HTTP-field: WWW-Authentication without HTTP-field Autorization'
    );
    isnt ( # negative testing, we should not get this content
        $res->content,
        qq|Access granted for default realm|,
        'Delivering: without HTTP-field Autorization'
    );
};


test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth');
    $req->authorization_basic ( 'foo', 'bar');
    my $res = $cb->( $req );
    is (
        $res->code,
        401,
        'Status 401: without proper credentials'
    );
    is (
        $res->headers->header('WWW-Authenticate'),
        qq|Basic realm="some_realm"|,
        'HTTP-field: WWW-Authentication without proper credentials'
    );
    isnt ( # negative testing, we should not get this content
        $res->content,
        qq|Access granted for default realm|,
        'Delivering: without proper credentials'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/auth');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        'Status 200: with the right credentials'
    );
    isnt ( # negative testing, we should not be required to authenticate
        $res->headers->header('WWW-Authenticate'),
        qq|Basic realm="some_realm"|,
        'HTTP-field: WWW-Authentication with the right credentials'
    );
    is (
        $res->content,
        qq|Access granted for default realm|,
        'Delivering: with the right credentials'
    );
};

#
# Roles
#

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/beer');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        'Status 200: BeerDrinker'
    );
    is (
        $res->content,
        qq|Enjoy your Beer!|,
        'Delivering: BeerDrinker'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/vodka');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        'Status 200: VodkaDrinker'
    );
    is (
        $res->content,
        qq|Enjoy your Vodka!|,
        'Delivering: VodkaDrinker'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/martini');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        403,
        'Status 403: not a MartiniDrinker'
    );
    is (
        $res->content,
        qq|Permission denied for resource: '/martini'|,
        'Delivering: not a MartiniDrinker'
    );
    isnt (
        $res->code,
        200,
        'Status 200: not a MartiniDrinker'
    );
    unlike (
        $res->content,
        qr|Enjoy your Martini!|,
        'Delivering: not a MartiniDrinker'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/juice');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        403,
        'Status 403: not a JuiceDrinker'
    );
    is (
        $res->content,
        qq|Permission denied for resource: '/juice'|,
        'Delivering: not a JuiceDrinker'
    );
    isnt (
        $res->code,
        200,
        'Status 200: not a JuiceDrinker'
    );
    unlike (
        $res->content,
        qr|Enjoy your Juice!|,
        'Delivering: not a JuiceDrinker'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/drinker');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        'Status 200: Regular Drinker'
    );
    is (
        $res->content,
        qq|Enjoy your bevarage!|,
        'Delivering: Regular Drinker'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/thirsty');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        'Status 200: Thirsty Drinker'
    );
    is (
        $res->content,
        qq|Enjoy your drinks, one at a time!|,
        'Delivering: Thirsty Drinker'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/alcohol');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        200,
        'Status 200: Alcoholic Drinker'
    );
    is (
        $res->content,
        qq|Enjoy your alcohol, but don't drink too much!|,
        'Delivering: Alcoholic Drinker'
    );
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new( GET => '/cocktail');
    $req->authorization_basic ( 'dave', 'beer');
    my $res = $cb->( $req );
    is (
        $res->code,
        403,
        'Status 403: not Bond, James Bond'
    );
    is (
        $res->content,
        qq|Permission denied for resource: '/cocktail'|,
        'Delivering: not Bond, James Bond'
    );
    isnt (
        $res->code,
        200,
        'Status 200: not Bond, James Bond'
    );
    unlike (
        $res->content,
        qr|Stirred, not shaken!|,
        'Delivering: not Bond, James Bond'
    );
};

done_testing();
