#!perl
use strict;
use utf8;
use warnings qw(all);

use FindBin qw($Bin $Script);
use Test::More;

use AnyEvent::Net::Curl::Queued;
use AnyEvent::Net::Curl::Queued::Easy;

my $q = AnyEvent::Net::Curl::Queued->new;

$q->append(
    AnyEvent::Net::Curl::Queued::Easy->new(
        http_response => 1,
        initial_url => "file://$Bin/$Script",
        on_finish => sub {
            my ($self, $result) = @_;

            is(0 + $result, 0, 'got CURLE_OK');
            ok(!$self->has_error, "libcurl message: '$result'");

            # AnyEvent::Net::Curl::Queued::Easy::res will be deprecated soon!
            is(ref($self->res), '', 'HTTP::Response leak');
        },
    )
);

$q->wait;

is($q->completed, 1, 'single fetch');

done_testing 4;
