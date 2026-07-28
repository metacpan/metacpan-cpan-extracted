#!perl -w

# Standard CSV file - ',' separator and the first column is not "entry"

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Database::test4;
use Test::Most tests => 4;
use Test::NoWarnings;

pass('Database::test4 loaded');
my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $test4 = new_ok('Database::test4' => [directory => $directory]);

cmp_ok($test4->ordinal(cardinal => 'one'), 'eq', 'first', 'CSV AUTOLOAD works');
