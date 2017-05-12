#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Digest::SHA qw(sha256_base64);
use Test::HTTP::AnyEvent::Server;
use Test::More;

my $server = Test::HTTP::AnyEvent::Server->new(forked => 1);

my $url = $server->uri . 'repeat/5/zxcvb';

use_ok('AnyEvent::Net::Curl::Queued::Easy');
use Net::Curl::Easy qw(:constants);

my $easy = AnyEvent::Net::Curl::Queued::Easy->new($url);
isa_ok($easy, qw(AnyEvent::Net::Curl::Queued::Easy));
can_ok($easy, qw(
    clone
    curl_result
    data
    final_url
    finish
    getinfo
    has_error
    header
    http_response
    init
    initial_url
    new
    on_finish
    on_init
    queue
    response
    retry
    setopt
    sha
    sign
    stats
    unique

    perform
));

$easy->init;

ok($easy->retry == 10, 'default retry()');

ok($easy->sign('TEST'), 'sign()');

# mock signature
my $digest = sha256_base64('AnyEvent::Net::Curl::Queued::Easy' . $url . 'TEST');
$digest =~ tr{+/}{-_};
ok($easy->unique eq $digest, 'URL uniqueness signature: ' . $easy->unique);

ok(($easy->perform // 0) == Net::Curl::Easy::CURLE_OK, 'perform()');
ok($easy->getinfo(Net::Curl::Easy::CURLINFO_RESPONSE_CODE) eq '200', '200 OK');

isa_ok($easy->stats, 'AnyEvent::Net::Curl::Queued::Stats');
ok($easy->stats->sum($easy), 'stats sum()');

ok($easy->stats->stats->{header_size} == length ${$easy->header}, 'headers size match');
ok($easy->stats->stats->{size_download} == length ${$easy->data}, 'body size match');

done_testing(12);
