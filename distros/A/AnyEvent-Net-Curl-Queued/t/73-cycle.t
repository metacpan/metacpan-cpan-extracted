#!perl
use strict;
use utf8;
use warnings qw(all);

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => q(these tests are for testing by the author));
    }
}

use FindBin qw($Bin $Script);
use Test::More;

## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
eval q(use Test::Memory::Cycle);
plan skip_all => q(Test::Memory::Cycle required)
    if $@;

use AnyEvent::Net::Curl::Queued;
use AnyEvent::Net::Curl::Queued::Easy;

my $q = AnyEvent::Net::Curl::Queued->new;
memory_cycle_ok($q, q(AnyEvent::Net::Curl::Queued after creation));

my $e = AnyEvent::Net::Curl::Queued::Easy->new(
    http_response => 1,
    initial_url => qq(file://$Bin/$Script),
    on_finish => sub {
        my ($self, $result) = @_;

        memory_cycle_ok($self->queue, q(AnyEvent::Net::Curl::Queued inside on_finish));
        memory_cycle_ok($self, q(AnyEvent::Net::Curl::Queued::Easy inside on_finish));

        is(0 + $result, 0, q(got CURLE_OK));
        ok(!$self->has_error, qq(libcurl message: '$result'));
    },
);
memory_cycle_ok($e, q(AnyEvent::Net::Curl::Queued::Easy after creation));

$q->append($e);
memory_cycle_ok($q, q(AnyEvent::Net::Curl::Queued after append));
memory_cycle_ok($e, q(AnyEvent::Net::Curl::Queued::Easy after append));

$q->wait;
memory_cycle_ok($q, q(AnyEvent::Net::Curl::Queued after wait));
memory_cycle_ok($e, q(AnyEvent::Net::Curl::Queued::Easy after wait));

is($q->completed, 1, q(single fetch));

done_testing 11;
