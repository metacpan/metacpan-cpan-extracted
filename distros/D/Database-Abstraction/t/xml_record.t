#!/usr/bin/env perl

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 2;

use_ok('Database::test6');

my $test6 = new_ok('Database::test6' => [directory => "$Bin/../data"]);

my @foo = $test6->selectall_hashref();

if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@foo])->Dump());
}

# TODO
# cmp_ok($test6->Country(ID => 104), 'eq', 'Australia', 'XML AUTOLOAD works found');
