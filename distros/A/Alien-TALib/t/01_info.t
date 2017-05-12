#!perl

use Test::More tests => 1;
use Alien::TALib;
my $talib = Alien::TALib->new;

diag 'Alien::TALib info';
diag 'is_installed : ' . $talib->is_installed || 'n.a.';
diag 'cflags       : ' . $talib->cflags || 'n.a.';
diag 'libs         : ' . $talib->libs || 'n.a.';

ok($talib);