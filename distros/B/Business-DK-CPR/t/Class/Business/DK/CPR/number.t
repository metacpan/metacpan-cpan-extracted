
use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

use Class::Business::DK::CPR;

my $cpr;

$cpr = Class::Business::DK::CPR->new(1501729996);

is($cpr->number(), 1501729996);
