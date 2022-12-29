#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 2;
use Data::Text;

isa_ok(Data::Text->new(), 'Data::Text', 'Creating Data::Text object');
isa_ok(Data::Text::new(), 'Data::Text', 'Creating Data::Text object');
# ok(!defined(Data::Text::new()));
