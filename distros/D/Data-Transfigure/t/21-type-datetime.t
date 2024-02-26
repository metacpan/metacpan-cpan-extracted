#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use DateTime;
use Data::Transfigure::Type::DateTime;
use Data::Transfigure::Constants;

my $dt = DateTime->new(year => 2000, month => 1, day => 1);
my $d  = Data::Transfigure::Type::DateTime->new();

is($d->applies_to(value => $dt),                  $MATCH_EXACT_TYPE, 'check applies_to type (DateTime)');
is($d->applies_to(value => bless({}, 'MyClass')), $NO_MATCH,         'check applies_to (negative) type (MyClass)');

is($d->transfigure($dt), '2000-01-01T00:00:00', 'check transfigure type (DateTime)');

done_testing;
