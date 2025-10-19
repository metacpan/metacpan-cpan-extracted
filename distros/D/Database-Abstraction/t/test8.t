#!perl -w

# Test PSV slurping with no entry column

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 5;

use_ok('Database::test8');

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $test8 = new_ok('Database::test8' => [directory => $directory, no_entry => 1]);

my @all = $test8->selectall_hash();

cmp_ok(scalar(@all), '==', 15, 'selectall_hash returns everything');

cmp_ok(scalar(@{$test8->selectall_arrayref()}), '==', 15, 'selectall_arrayref returns all entries');
cmp_ok($test8->count(), '==', 15, 'count returns all correct number');
