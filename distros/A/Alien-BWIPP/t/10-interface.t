#!perl -T
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 2;

use Alien::BWIPP;
my $class = 'Alien::BWIPP';
can_ok($class, qw(import create_classes encoders_meta_classes));
ok(scalar @{$class->encoders_meta_classes}, 'class attribute is populated');
