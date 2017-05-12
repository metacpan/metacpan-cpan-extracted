use strict;
use warnings;

## Test Frameworks
use Test::More import => ["!pass"], tests => 2;                      # last test to print
use Dancer::Test;

## Module to be tested
use Dancer::Plugin::BeforeRoute;

## Setup dancer routes
use Dancer qw(:syntax);

before_route get => "/here" => sub {
    var here => 300;
};

get "/here" => sub {
    status(var "here");
};

## Start test
response_status_is [GET => "/here"], 300, "check get method";
response_status_is [HEAD => "/here"], 300, "check head method";
