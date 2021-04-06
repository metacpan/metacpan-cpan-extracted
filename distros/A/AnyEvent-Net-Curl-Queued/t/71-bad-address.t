#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use AnyEvent::Net::Curl::Queued;
use AnyEvent::Net::Curl::Queued::Easy;

local $ENV{no_proxy} = '*';

my $q = AnyEvent::Net::Curl::Queued->new;

$q->append(
    AnyEvent::Net::Curl::Queued::Easy->new(
        initial_url => 'http://0.0.0.0/',
        http_response => 1,
        on_finish   => sub {
            my ($self, $result) = @_;
            ok($self->has_error, "error detected");
            ok($self->response->message eq '', "empty HTTP::Response");
            ok($result == Net::Curl::Easy::CURLE_COULDNT_CONNECT, "couldn't connect")
                || diag $result;
        },
        retry => 3,
    )
);

$q->wait;

done_testing(9);
