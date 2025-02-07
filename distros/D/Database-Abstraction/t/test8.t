#!perl -w

# Test PSV slurping

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 3;

use_ok('Database::test8');

my $test8 = new_ok('Database::test8' => [directory => "$Bin/../data", no_entry => 1]);

my @all = $test8->selectall_hash();

cmp_ok(scalar(@all), '==', 15, 'selectall_hash returns everything');
