use strict;
use warnings;

## Test Frameworks
use Test::More import => ["!pass"], tests => 2;    # last test to print
use HTTP::Request::Common;
use Plack::Test;

## Setup dancer routes
{

    package MyApp;
    use Dancer2 qw(:syntax);
    ## Module to be tested
    use Dancer2::Plugin::BeforeRoute;

    set logger        => "console";
    set log           => "error";
    set show_errors   => 1;
    set show_warnings => 1;

    before_route get => "/here" => sub {
        var here => 300;
    };

    get "/here" => sub {
        status( var "here" );
    };
}

## Start test
my $app = Plack::Test->create( MyApp->to_app );
is $app->request( GET '/here' )->code,  300;
is $app->request( HEAD '/here' )->code, 300;
