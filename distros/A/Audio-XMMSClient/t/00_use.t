#!perl

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('Audio::XMMSClient');
}

ok( exists $Audio::{'XMMSClient::'}, 'Audio::XMMSClient loaded correctly' );
ok( exists $Audio::XMMSClient::{'Result::'}, ' ... and bootstrapped Audio::XMMSCLient::Result' );
ok( exists $Audio::XMMSClient::Result::{'PropDict::'}, ' ... and bootstrapped Audio::XMMSClient::Result::PropDict' );
ok( exists $Audio::XMMSClient::Result::PropDict::{'Tie::'}, ' ... and bootstrapped Audio::XMMSClient::Result::PropDict::Tie' );
