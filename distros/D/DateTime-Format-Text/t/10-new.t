#!perl -wT

use warnings;
use strict;
use Test::Most tests => 4;

use_ok ('DateTime::Format::Text');

isa_ok(DateTime::Format::Text->new(), 'DateTime::Format::Text', 'Creating DateTime::Format::Text object');
isa_ok(DateTime::Format::Text->new()->new(), 'DateTime::Format::Text', 'Cloning DateTime::Format::Text object');
isa_ok(DateTime::Format::Text::new(), 'DateTime::Format::Text', 'Creating DateTime::Format::Text object');
# ok(!defined(DateTime::Format::Text::new()));
