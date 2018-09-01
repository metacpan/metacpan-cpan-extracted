
use strict;
use warnings;

use Context::Singleton;

use Test::More tests => 1 + 2;
use Test::Warnings;

singleton child => (
	provides => 'parent',
);

proclaim child => 10;

ok is_deducible ('parent'), 'parent is deducible';
is deduce ('parent'), 10, 'parent has value';

