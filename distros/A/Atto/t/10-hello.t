#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;


use Atto qw(hello);

sub hello {
    return "hello world";
}

my $app = Atto->psgi;


my $test = Plack::Test->create($app);
my $json = JSON::MaybeXS->new->utf8->allow_nonref;

my $res = $test->request(POST "/hello");
ok $res->is_success, "request to /hello succeeded";

is $json->decode($res->content), "hello world", "request returned expected response";

done_testing;
