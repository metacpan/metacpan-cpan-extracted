#!perl -wT

use strict;
use FindBin qw($Bin);

use File::Spec;
use Test::Most tests => 6;
use Test::NoWarnings;

use lib 't/lib';
use Database::cities;
use Database::states;
use_ok('Database::Join');

pass('Database::cities loaded');
my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $cities = new_ok('Database::cities' => [$directory]);
my $states = new_ok('Database::states' => [$directory]);
my $joined = Database::Join->new({
	databases => [$cities, $states],
	join_column => 'statecode',
        join_map => { 1 => 'entry' },   # database 1 ($states) name for the join_column
});

# diag(Data::Dumper->new([$joined->selectall_arrayref()])->Dump());
cmp_ok($joined->state('Laurel'), 'eq', 'Maryland');
