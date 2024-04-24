#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 3;
use DateTime::Format::Genealogy;

isa_ok(DateTime::Format::Genealogy->new(), 'DateTime::Format::Genealogy', 'Creating DateTime::Format::Genealogy object');
isa_ok(DateTime::Format::Genealogy::new(), 'DateTime::Format::Genealogy', 'Creating DateTime::Format::Genealogy object');
isa_ok(DateTime::Format::Genealogy->new()->new, 'DateTime::Format::Genealogy', 'Cloning DateTime::Format::Genealogy object');
# ok(!defined(DateTime::Format::Genealogy::new()));
