use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use DBI;

use DBIx::Tree;

use File::Spec;
use File::Temp;

use Test::More;

our $compare;
our $rc;

our $loaded = 0;

# ------------------------------------------------

sub display_tree
{
	my(%param) = @_;
	my $item = $param{item};
	$item =~ s/^\s+//;
	$item =~ s/\s+$//;

	$compare .= $item;

} # End of display_tree.

# ------------------------------------------------

$loaded = 1;

ok($loaded == 1, 'Module loaded');

############# create and populate the table we need.

my($dir)  = File::Temp -> newdir;
my($file) = File::Spec -> catfile($dir, 'test.sqlite');
my(@opts) =
(
$ENV{DBI_DSN}  || "dbi:SQLite:dbname=$file",
$ENV{DBI_USER} || '',
$ENV{DBI_PASS} || '',
);

my $dbh = DBI->connect(@opts, {RaiseError => 0, PrintError => 1, AutoCommit => 1});

ok(defined $dbh, "Connected to $opts[0]");

diag 'You may get a warning here: DBD::SQLite::db prepare failed: no such table: food. Just ignore it';

my($error) = open(my $fh, '<', 't/INSTALL.SQL');

ok($error, 'Opened t/INSTALL.SQL for reading!');

while(<$fh>)
{
	chomp;

	# strip out NULL for mSQL

	if (/^create/i and $opts[0] =~ /msql/i) {
	    s/null//gi;
	}

	my $sth = $dbh->prepare($_);

	# Skip failure to drop non-existent table.

	next if (! defined $sth);

	my $rc = $sth->execute;

	# ignore drop table.

	if (!$rc)
	{
		if (/^drop/i)
		{
			diag 'Ignoring failed DROP operation';
		}
		else
		{
			diag "Failed drop statement: $DBI::errstr";
		}
	}
}

close ($fh);

############# create an instance of the DBIx::Tree
{
	# Test traverse().

	my $tree = DBIx::Tree -> new
		(
			connection => $dbh,
			table      => 'food',
			method     => sub { display_tree(@_) },
			columns    => ['id', 'food', 'parent_id'],
			start_id   => '001',
		);

	ok(ref $tree eq 'DBIx::Tree', 'Create object to read table');

	ok($tree -> _do_query, 'Executed query');

	$tree->traverse;

	ok($compare eq 'FoodBeans and NutsBeansBlack BeansKidney BeansBlack Kidney BeansRed Kidney BeansNutsPecansDairyBeveragesCoffee MilkSkim MilkWhole MilkCheesesCheddarGoudaMuensterStiltonSwiss', 'Called traverse()');
}


{
	# Test match_data.

	my $tree = DBIx::Tree -> new
		(
			connection => $dbh,
			table      => 'food',
			method     => sub { display_tree(@_) },
			columns    => ['id', 'food', 'parent_id'],
			start_id   => '001',
			match_data => 'Dairy',
		);

	$compare = '';

	$tree->traverse;

	ok($compare eq 'Dairy', 'Another traverse()');

	# Test traverse().

	$compare = '';

	$tree->traverse(start_id => '011', threshold => 2, match_data => '', limit => 2);

	ok($compare eq 'Coffee MilkSkim Milk', 'Test local variables in traverse()');

	$compare = '';

	$tree->traverse;

	ok($compare eq 'Dairy', 'Test default values in traverse()');
}

{
	# Test 'sth' in new().

	my $sth = $dbh->prepare('select id, food, parent_id from food order by food');
	my $tree = DBIx::Tree -> new
		(
			connection => $dbh,
			sth        => $sth,
			method     => sub { display_tree(@_) },
			columns    => ['id', 'food', 'parent_id'],
			start_id   => '001',
		);

	$compare = '';

	$tree->traverse;

	ok($compare eq 'FoodBeans and NutsBeansBlack BeansKidney BeansBlack Kidney BeansRed Kidney BeansNutsPecansDairyBeveragesCoffee MilkSkim MilkWhole MilkCheesesCheddarGoudaMuensterStiltonSwiss', 'sth in new()');
}

{
	# Test 'sql' in new().

	my $sql = 'select id, food, parent_id from food order by food';
	my $tree = DBIx::Tree -> new
		(
			connection => $dbh,
			sql        => $sql,
			method     => sub { display_tree(@_) },
			columns    => ['id', 'food', 'parent_id'],
			start_id   => '001',
		);

	$compare = '';

	$tree->traverse;

	ok($compare eq 'FoodBeans and NutsBeansBlack BeansKidney BeansBlack Kidney BeansRed Kidney BeansNutsPecansDairyBeveragesCoffee MilkSkim MilkWhole MilkCheesesCheddarGoudaMuensterStiltonSwiss', 'sql in new()');

	# Test recursive option to traverse().

	$compare = '';

	$tree->traverse(recursive => 1);

	ok($compare eq 'FoodBeans and NutsBeansBlack BeansKidney BeansBlack Kidney BeansRed Kidney BeansNutsPecansDairyBeveragesCoffee MilkSkim MilkWhole MilkCheesesCheddarGoudaMuensterStiltonSwiss', 'recursive option to traverse()');
}

$dbh->do(q{drop table food});
$dbh->disconnect;

done_testing;
