#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 6;

use_ok('Data::Displaycolour');

my $dp = Data::Displaycolour->new(for_text => 'YeLlOw');

isa_ok($dp, 'Data::Displaycolour');
ok(defined($dp->rgb(default => undef, no_defaults => 1)), 'Has RGB');
ok(defined($dp->abstract('Data::Identifier', default => undef, no_defaults => 1)), 'Has abstract (Data::Identifier)');
ok(defined($dp->specific('Data::Identifier', default => undef, no_defaults => 1)), 'Has specific (Data::Identifier)');
ok(defined($dp->specific('Data::URIID::Colour', default => undef, no_defaults => 1)), 'Has specific (Data::URIID::Colour)');

exit 0;
