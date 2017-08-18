#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('AtteanX::Compatibility::Trine');

use_ok('Attean::Literal');

can_ok('Attean::Literal', 'literal_value');
can_ok('Attean::Literal', 'literal_value_language');
can_ok('Attean::Literal', 'has_datatype');
can_ok('Attean::Literal', 'literal_datatype');

my $lit = Attean::Literal->new(value => 'Dahut', language => 'fr');

ok($lit->has_datatype, 'All have datatype in RDF 1.1');
is($lit->literal_value, 'Dahut', 'Value roundtripped');
is($lit->literal_value_language, 'fr', 'Language roundtripped');
is($lit->literal_datatype, 'http://www.w3.org/2001/XMLSchema#langString', 'Got langString data type');

done_testing;
