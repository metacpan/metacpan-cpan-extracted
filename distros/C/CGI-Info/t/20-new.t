#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 4;

use_ok('CGI::Info');

isa_ok(CGI::Info->new(), 'CGI::Info', 'Creating CGI::Info object');
isa_ok(CGI::Info::new(), 'CGI::Info', 'Creating CGI::Info object');
isa_ok(CGI::Info->new()->new(), 'CGI::Info', 'Cloning CGI::Info object');
# ok(!defined(CGI::Info::new()));
