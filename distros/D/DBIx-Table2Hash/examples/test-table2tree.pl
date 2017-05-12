#!/usr/bin/perl
#
# Name:
#	test-table2tree.pl.
#
# Purpose:
#	Test DBIx::Table2Hash::hash2tree.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html
#
# Note:
#	tab = 4 spaces || die.

use strict;
use warnings;

use Data::Dumper;
use DBI;
use DBIx::Table2Hash;
use Error qw/:try/;
use FindBin;

# -----------------------------------------------

sub test
{
	my($dbh) = @_;

	print "Read table into hash tree. \n";
	print "\n";

	my($tree) = DBIx::Table2Hash -> new
	(
		dbh				=> $dbh,
		table_name		=> 'hobbit',
		key_column		=> 'name', # or even "concat(name, '-', id)",
	) -> select_tree(child_column => 'id', parent_column => 'parent_id');

	print "Dump hash tree. \n";
	print "\n";

	$Data::Dumper::Indent = 1;
	print Data::Dumper->Dump([$tree], ['$tree']);

}	# End of test.

# -----------------------------------------------

print "$0. \n";
print "\n";

try
{
	my($dbh) = DBI -> connect
	(
		'DBI:mysql:test:127.0.0.1', 'route', 'bier',
		{
			AutoCommit			=> 1,
			HandleError			=> sub {Error::Simple -> record($_[0]); 0},
			PrintError			=> 0,
			RaiseError			=> 1,
			ShowErrorStatement	=> 1,
		}
	);

	test($dbh);
}
catch Error::Simple with
{
	my($error) = $_[0] -> text();
	chomp $error;
	print $error;
};
