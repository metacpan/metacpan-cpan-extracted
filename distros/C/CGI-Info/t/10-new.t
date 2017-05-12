#!perl -wT

use strict;

use Test::Most tests => 2;

use CGI::Info;

isa_ok(CGI::Info->new(), 'CGI::Info', 'Creating CGI::Info object');
ok(!defined(CGI::Info::new()));
