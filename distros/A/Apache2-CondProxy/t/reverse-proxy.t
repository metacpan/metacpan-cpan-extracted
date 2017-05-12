#!perl

use strict;
use warnings;

use Apache::Test qw(:withtestmore);
use Apache::TestRequest qw(GET_OK);

plan test => 2;#,
#    need_module qw(mod_proxy.c mod_proxy_http.c mod_proxy_connect.c);

ok GET_OK('/index.html');

ok GET_OK('/');
