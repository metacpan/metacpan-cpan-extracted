#!perl -wT

use strict;

use Test::Most tests => 2;

use Data::Fetch;

isa_ok(Data::Fetch->new(), 'Data::Fetch', 'Creating Data::Fetch object');
ok(!defined(Data::Fetch::new()));
