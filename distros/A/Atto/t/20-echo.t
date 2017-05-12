#!perl

use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;


use Atto qw(echo);

sub echo {
    my %args = @_;
    return { echo => \%args };
}

my $app = Atto->psgi;

my $test = Plack::Test->create($app);
my $json = JSON::MaybeXS->new->utf8->allow_nonref;

{
    my $res = $test->request(POST "/echo");
    ok $res->is_success, "request to /echo succeeded";
    is_deeply $json->decode($res->content), { echo => {} }, "echo without args returned expected response";
}

{
    my $res = $test->request(POST "/echo", "Content-type" => "application/json", Content => $json->encode({ foo => "bar" }));
    ok $res->is_success, "request to /echo succeeded";
    is_deeply $json->decode($res->content), { echo => { foo => "bar" } }, "echo with JSON args returned expected response";
}

{
    my $res = $test->request(POST "/echo", { foo => "bar" });
    ok $res->is_success, "request to /echo succeeded";
    is_deeply $json->decode($res->content), { echo => { foo => "bar" } }, "echo with form args returned expected response";
}

{
    my $res = $test->request(GET "/echo?foo=bar");
    ok $res->is_success, "request to /echo succeeded";
    is_deeply $json->decode($res->content), { echo => { foo => "bar" } }, "echo with form args returned expected response";
}

done_testing;
