#!perl

use strict;
use Apache::Test;
use Apache::TestRequest 'GET_BODY_ASSERT';

plan tests=>3;

my $body=GET_BODY_ASSERT "/b?Apache2::Banner::banner";
ok $body, qr!mod_perl/!;

$body=GET_BODY_ASSERT "/b?Apache2::Banner::description";
ok $body, qr!mod_perl/!;

$body=GET_BODY_ASSERT "/d";
ok $body, 'Sun, 09 Sep 2001 01:46:40 GMT';
