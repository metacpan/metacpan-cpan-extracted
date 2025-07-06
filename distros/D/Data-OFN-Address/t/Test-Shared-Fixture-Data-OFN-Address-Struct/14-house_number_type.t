use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::Struct;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::Struct->new;
is($obj->house_number_type, decode_utf8('č.p.'), 'Get house number_type (č.p.).');
