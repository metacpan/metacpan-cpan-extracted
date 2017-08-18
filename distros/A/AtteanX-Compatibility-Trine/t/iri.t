#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('AtteanX::Compatibility::Trine');
use_ok('Attean::IRI');

can_ok('Attean::IRI', 'uri');

my $iri = Attean::IRI->new('http://example.org/dahut');

is($iri->uri, 'http://example.org/dahut', 'IRI roundtripped OK');

done_testing;
