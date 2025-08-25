#!perl -w

# Test where the entry field is not unique

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 6;

use_ok('Database::test7');

my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
my $test7 = new_ok('Database::test7' => [directory => $directory]);

my @sections = $test7->section({ entry => 'A7' });
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@sections])->Dump());
}

cmp_ok(scalar(@sections), '==', 4, 'All sections are found');

my @s = @{$test7->selectall_hashref(entry => 'A7')};
if($ENV{'TEST_VERBOSE'}) {
	use Data::Dumper;
	diag(Data::Dumper->new([\@s])->Dump());
}
cmp_ok(scalar(@s), '==', 4, 'All sections are found');

@s = $test7->selectall_hash({ entry => 'A7' });
cmp_ok(scalar(@s), '==', 4, 'All sections are found');

my $rc = $test7->selectall_hashref('A7');
cmp_ok(scalar(@{$rc}), '==', 4, 'All sections are found, entry is implied argument');
