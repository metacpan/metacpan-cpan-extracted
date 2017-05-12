#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;
use Test::Warn;

use_ok('AnyEvent::Net::Curl::Const');
use Net::Curl::Easy;

my $value = eval { Net::Curl::Easy::CURLOPT_TCP_NODELAY };
ok(!$@, 'Net::Curl::Easy::CURLOPT_TCP_NODELAY defined');

ok($value = AnyEvent::Net::Curl::Const::opt($_), "'$_' defined")
    for qw(
        Net::Curl::Easy::CURLOPT_TCP_NODELAY
        CURLOPT_TCP_NODELAY
        TCP_NODELAY
        TCP-NoDelay
        tcp_nodelay
    );

$value = eval { Net::Curl::Easy::CURLINFO_EFFECTIVE_URL };
ok(!$@, 'Net::Curl::Easy::CURLINFO_EFFECTIVE_URL defined');

ok($value = AnyEvent::Net::Curl::Const::info($_), "'$_' defined")
    for qw(
        Net::Curl::Easy::CURLINFO_EFFECTIVE_URL
        CURLINFO_EFFECTIVE_URL
        EFFECTIVE_URL
        Effective-URL
        effective_url
    );

warning_like
    { AnyEvent::Net::Curl::Const::info('no_such_constant') }
    [qr{Invalid\s+libcurl\s+constant:\s+CURLINFO_NO_SUCH_CONSTANT}x],
    'undefined constant';

done_testing(14);
