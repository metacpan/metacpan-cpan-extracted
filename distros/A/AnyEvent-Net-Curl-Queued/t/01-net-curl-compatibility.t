#!perl
# shamelessly borrowed from Net::Curl t/compat-19multi.t
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use Test::HTTP::AnyEvent::Server;
use AnyEvent::Net::Curl::Queued::Easy;
use AnyEvent::Net::Curl::Queued::Multi;

use Net::Curl::Easy qw(:constants);
use Net::Curl::Multi qw(:constants);

my $server = Test::HTTP::AnyEvent::Server->new(forked => 1);

my $url = $server->uri . 'echo/head';

my $last_fdset = '';
my $last_cnt = 0;

my $curl = AnyEvent::Net::Curl::Queued::Easy->new($url);
isa_ok($curl, qw(AnyEvent::Net::Curl::Queued::Easy));
can_ok($curl, qw(init _finish));

$curl->init;
ok($curl->{private} = "foo", "Setting private data");

my $curl2 = AnyEvent::Net::Curl::Queued::Easy->new(initial_url => $url);
isa_ok($curl2, qw(AnyEvent::Net::Curl::Queued::Easy));
can_ok($curl2, qw(init _finish));

$curl2->init;
ok($curl2->{private} = 42, "Setting private data");

my $curlm = AnyEvent::Net::Curl::Queued::Multi->new({ pool => {} });
isa_ok($curlm, qw(AnyEvent::Net::Curl::Queued::Multi));

can_ok($curlm, qw(CURLMOPT_TIMERFUNCTION));
is(
    CURL_POLL_IN |
    CURL_POLL_OUT,
    CURL_POLL_INOUT,
    "CURL_POLL_INOUT == CURL_POLL_IN + CURL_POLL_OUT"
);

my @fds = $curlm->fdset;
ok(@fds == 3 && ref($fds[0]) eq '' && ref($fds[1]) eq '' && ref($fds[2]) eq '', "fdset returns 3 vectors");
ok(!$fds[0] && !$fds[1] && !$fds[2], "The three returned vectors are empty");
$curlm->perform;

@fds = $curlm->fdset;
ok(!$fds[0] && !$fds[1] && !$fds[2], "The three returned vectors are still empty after perform");
$curlm->add_handle($curl);
@fds = $curlm->fdset;
ok(!$fds[0] && !$fds[1] && !$fds[2], "The three returned vectors are still empty after perform and add_handle");
$curlm->perform;

@fds = $curlm->fdset;
my $cnt;
$cnt = unpack("%32b*", $fds[0].$fds[1]);
ok(1, "The read or write fdset contains one fd (is $cnt)");
$curlm->add_handle($curl2);

@fds = $curlm->fdset;
$cnt = unpack("%32b*", $fds[0].$fds[1]);
ok(1, "The read or write fdset still only contains one fd (is $cnt)");
$curlm->perform;

@fds = $curlm->fdset;
$cnt = unpack("%32b*", $fds[0].$fds[1]);
ok(2, "The read or write fdset contains two fds (is $cnt)");
my $active = 2;

while ($active != 0) {
    my $ret = $curlm->perform;
    if ($ret != $active) {
        while (my ($msg, $_curl, $result) = $curlm->info_read) {
            is($msg, CURLMSG_DONE, "Message is CURLMSG_DONE");
            $curlm->remove_handle($_curl);
            ok($_curl && ($_curl->{private} eq "foo" || $_curl->{private}  == 42), "The stored private value matches what we set ($_curl->{private})");
        }
        $active = $ret;
    }
    action_wait($curlm);
}

@fds = $curlm->fdset;
ok(!$fds[0] && !$fds[1] && !$fds[2], "The three returned arrayrefs are empty after we have no active transfers");
ok(${$curl->header}, "Header reply exists from first handle");
ok(${$curl->data}, "Body reply exists from second handle");
ok(${$curl2->header}, "Header reply exists from second handle");
ok(${$curl2->data}, "Body reply exists from second handle");

done_testing(25);


sub action_wait {
    my $_curlm = shift;
    my ($rin, $win, $ein) = $_curlm->fdset;
    my $timeout = $_curlm->timeout;

    if ($timeout > 0) {
        my ($nfound, $timeleft) = select($rin, $win, $ein, $timeout / 1000);
    }

    return;
}
