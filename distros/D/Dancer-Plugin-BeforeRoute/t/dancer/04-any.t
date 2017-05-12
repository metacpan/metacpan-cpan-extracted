use strict;
use warnings;

## Test Frameworks
use Test::More import => ["!pass"], tests => 10;    # last test to print
use Dancer::Test;

## Module to be tested.
use Dancer::Plugin::BeforeRoute;

## Setup Dancer Testing Routes
use Dancer qw( :syntax );

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

## Start test
my @testing_methods = qw( get post put delete head );
foreach my $method (@testing_methods) {
    response_content_is( [ $method => "/here" ],
        1, "set var in before route with $method method" );
    response_content_is(
        [ $method => "/there" ],
        q{},
"try to access other route to access /here before route set var with $method method"
    );
}
