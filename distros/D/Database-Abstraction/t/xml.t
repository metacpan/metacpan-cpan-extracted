#!perl -w

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 3;

use_ok('Database::test3');

my $test3 = new_ok('Database::test3' => ["$Bin/../data"]);

cmp_ok($test3->fr('2'), 'eq', 'Deux', 'XML AUTOLOAD works');
