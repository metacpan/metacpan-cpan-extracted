#!perl -w

# FIXME: Slurping mode fails on this

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 10;

use_ok('Database::test3');

my $test3 = new_ok('Database::test3' => [{
	directory => "$Bin/../data",
	max_slurp_size => 1	# force to not use slurp and therefore to use SQL
}]);

cmp_ok($test3->fr('2'), 'eq', 'Deux', 'XML AUTOLOAD works found');
is($test3->fr('4'), undef, 'XML AUTOLOAD works not found');

my @rc = $test3->entry(distinct => 1);
cmp_ok(scalar(@rc), '==', 3, 'getting all the distinct entries works');

@rc = $test3->entry();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}
cmp_ok(scalar(@rc), '==', 3, 'getting all the entries works');

my $rc = $test3->selectall_hashref();
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([$rc])->Dump());
}

cmp_ok(scalar(@{$rc}), '==', 3, 'selectall_hashref returns all entries');

@rc = $test3->selectall_hash('fr' => 'Deux');

if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@rc])->Dump());
}

cmp_ok(scalar(@rc), '==', 2, 'selectall_hash returns correct number of matches');

ok(($rc[0]->{'fr'} eq 'Deux') && ($rc[1]->{'fr'} eq 'Deux'));

cmp_ok($test3->updated(), '<', time, 'Updated is a time in the past');
