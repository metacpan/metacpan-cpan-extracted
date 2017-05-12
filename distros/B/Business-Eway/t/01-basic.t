#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;

use Business::Eway;
use URI::Escape qw/uri_escape/;

my $eway = Business::Eway->new(
    CustomerID => 87654321,
    UserName => 'TestAccount',
);
isa_ok($eway, 'Business::Eway');

my $url = $eway->request_url(
    Amount => 10,
    Currency => 'USD',
    CancelURL => 'http://www.google.com/ig',
    ReturnUrl => 'http://fayland.org/blog/',
);

ok( index($url, 'CustomerID=87654321') > -1, 'CustomerID' );
ok( index($url, 'UserName=TestAccount') > -1, 'UserName' );
ok( index($url, 'Amount=10.00') > -1, '10.00' );
ok( index($url, 'Currency=USD') > -1, 'USD' );
ok( index($url, 'CancelURL=' . uri_escape('http://www.google.com/ig')) > -1, 'CancelURL' );
ok( index($url, 'ReturnUrl=' . uri_escape('http://fayland.org/blog/')) > -1, 'ReturnUrl' );

my $key = '611a5cabc19330f52f9db09e4549c225dda64a71aa8775f53cafce75c0acff0b611a5cabc19330f52f9db09e4549c225dda64a71aa8775f5asdfalkji323jlJS';
$url = $eway->result_url($key);
ok( index($url, 'CustomerID=87654321') > -1, 'CustomerID' );
ok( index($url, 'UserName=TestAccount') > -1, 'UserName' );
ok( index($url, "AccessPaymentCode=$key") > -1, $key );

1;