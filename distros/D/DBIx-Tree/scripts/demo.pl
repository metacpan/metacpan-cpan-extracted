#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

use DBIx::Tree;

use File::Spec;
use File::Temp;

# ------------------------------------------------

sub display_tree
{
	my(%param)  = @_;
	my($item)   = $param{item};
	$item       =~ s/^\s+//;
	$item       =~ s/\s+$//;
	my($indent) = '  ' x ($param{level} - 1);
	my($s)      = "$indent$item ($param{id}). Parents: ";
	my($count)  = $#{$param{parent_id} };

	if ($param{level} > 1)
	{
		$s .= join(' -> ', map{"$param{parent_name}[$count - $_] ($param{parent_id}[$count - $_])"} 0 .. $count);
	}

	print "$s\n";

} # End of display_tree.

# ------------------------------------------------

my($dir)  = File::Temp -> newdir;
my($file) = File::Spec -> catfile($dir, 'test.sqlite');
my(@opts) =
(
$ENV{DBI_DSN}  || "dbi:SQLite:dbname=$file",
$ENV{DBI_USER} || '',
$ENV{DBI_PASS} || '',
);

print "Building the table...\n";

my $dbh = DBI->connect(@opts, {RaiseError => 0, PrintError => 1, AutoCommit => 1});

my($error) = open(my $fh, '<', 't/INSTALL.SQL');

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
}

close ($fh);

print "Processing the table...\n";

my $tree = DBIx::Tree -> new
	(
		connection => $dbh,
		table      => 'food',
		method     => sub { display_tree(@_) },
		columns    => ['id', 'food', 'parent_id'],
		start_id   => '001',
	);

$tree->traverse;

$dbh->do(q{drop table food});
$dbh->disconnect;
