#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use DateTime::Duration;
use Data::Transfigure::Type::DateTime::Duration;
use Data::Transfigure::Constants;

my $dt = DateTime::Duration->new(minutes => 8, seconds => 15);
my $d  = Data::Transfigure::Type::DateTime::Duration->new();

is($d->applies_to(value => $dt),                  $MATCH_EXACT_TYPE, 'check applies_to type (DateTime::Duration)');
is($d->applies_to(value => bless({}, 'MyClass')), $NO_MATCH,         'check applies_to (negative) type (MyClass)');

is($d->transfigure($dt), 'PT8M15S', 'check transfigure type (DateTime::Duration)');

done_testing;
