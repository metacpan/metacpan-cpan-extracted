#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 4;

use_ok('Data::Text');

isa_ok(Data::Text->new(), 'Data::Text', 'Creating Data::Text object');
isa_ok(Data::Text->new()->new(), 'Data::Text', 'Cloning Data::Text object');
isa_ok(Data::Text::new(), 'Data::Text', 'Creating Data::Text object');
# ok(!defined(Data::Text::new()));
