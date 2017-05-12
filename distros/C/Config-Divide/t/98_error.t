use strict;
use lib 't/lib';
use Config::Divide;
use Test::Exception;
use Test::More tests => 1;

throws_ok { Config::Divide->load_config() } qr/invalid args/;
