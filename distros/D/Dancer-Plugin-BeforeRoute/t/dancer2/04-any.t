use strict;
use warnings;

## Test Frameworks
use Test::More import => ["!pass"];    # last test to print
use Plack::Test;
use HTTP::Request::Common;

## Setup Dancer2 Testing Routes
{

    package MyApp;
    use Dancer2;

    set logger        => "console";
    set log           => "error";
    set show_errors   => 1;
    set show_warnings => 1;

    ## Module to be tested.
    use Dancer2::Plugin::BeforeRoute;

    before_route any => "/here" => sub {
        var
          here => 1,
          ;
    };

    any "/here" => sub {
        return var "here";
    };

    any "/there" => sub {
        return var "here";
    };
}

## Start test

my $app = Plack::Test->create( MyApp->to_app );
my @testing_methods = map { uc } qw( get post put delete);

METHOD: foreach my $method (@testing_methods) {
    is $app->request( HTTP::Request::Common->can($method)->('/here') )->content,
      1, "set var in before route with $method method";
    is $app->request( HTTP::Request::Common->can($method)->('/there') )->content,
      q{},
"try to access other route to access /here before route set var with $method method";
}

done_testing;
