#!/usr/bin/perl -w
#
#	@(#)$Id: metadata.t,v 57.4 1997/11/18 05:28:53 johnl Exp $ 
#
#	Test MetaData functions _tables, _columns for DBD::Sqlflex
#
#	Copyright (C) 1997 Jonathan Leffler

use DBD::SqlflexTest;

print "1..4\n";

# Test connection
$dbh = &connect_to_test_database(0, { AutoCommit => 1, PrintError => 1 });

$view = "dbd_ix_view01";
$private1 = "dbd_ix_private01";
$private2 = "'informix'.dbd_ix_private02";
$public1 = "dbd_ix_public01";

# Drop pre-existing versions of views and synonyms (unchecked)
$dbh->{PrintError} = 0;
$dbh->do("DROP VIEW $view");
$dbh->do("DROP SYNONYM $public1");
$dbh->do("DROP SYNONYM $private1");
$dbh->do("DROP SYNONYM $private2");
$dbh->{PrintError} = 1;
stmt_ok();

$dbh->do(qq{
CREATE VIEW $view AS
	SELECT T.Owner, T.TabName, T.TabType, C.ColNo, C.ColName
		FROM 'informix'.SysTables T, 'informix'.SysColumns C
		WHERE C.Tabid = T.Tabid}
		)
	or die "DBI::errstr";

# Public and private synonyms were introduced in version 5.00.
# You cannot use PUBLIC or PRIVATE in a MODE ANSI database.
$public = "PUBLIC";
$private = "PRIVATE";
if ($dbh->{ix_ModeAnsiDatabase})
{
	$public = "";
	$private = "";
}

$dbh->do("CREATE $public SYNONYM $public1 FOR 'informix'.SysColumns")
	or die "DBI::errstr";
$dbh->do("CREATE $private SYNONYM $private1 FOR 'informix'.SysTables")
	or die "DBI::errstr";
$dbh->do("CREATE $private SYNONYM $private2 FOR 'informix'.SysTables")
	or die "DBI::errstr";
stmt_ok();

sub print_tables
{
	my ($dbh, @ctrl) = @_;
	my @list = $dbh->func(@ctrl, '_tables');
	print "# Information about @ctrl tables in $dbh->{Name}\n";
	my $item;
	for $item (@list)
	{
		print "# $item\n";
	}
}

sub print_columns
{
	my ($dbh, @tables) = @_;
	my @list = $dbh->func(@tables, '_columns');
	my $plural = ($#list > 0) ? "s" : "";
	print "# Information about columns in table$plural @tables\n";
	my $rowref;
	for $rowref (@list)
	{
		my @row = @{$rowref};
		my $tab = "'$row[0]'.$row[1]";
		my $nulls = ($row[4] >= 256) ? "N" : "Y";
		$row[4] -= 256 if ($row[4] > 256);
		printf "# %-30s %3d %-18s %s %4d %4d\n", $tab, $row[2], $row[3],
				$nulls, $row[4], $row[5];
	}
}

print "# DBI Version $DBI::VERSION\n";
print "# DBD::Sqlflex version $dbh->{Driver}->{Version}\n";
print "# Database $dbh->{Name}\n";
$dbh->{ChopBlanks} = 1;

print_tables($dbh, 'view');
# Verify correct number of entries?
print_tables($dbh, 'base', 'user');
# Verify correct number of entries?
print_tables($dbh, 'base', 'system');
# Verify correct number of entries?
print_tables($dbh, 'synonym', 'tables');
# Verify correct number of entries?
print_tables($dbh, 'system');
# Verify correct number of entries?
print_tables($dbh);
stmt_ok();

my @list = $dbh->func('user', '_tables');
for ($i = 1; $i < $#list; $i += 2)
{
	# Remove owner names from every other table name
	$list[$i] =~ s/'[^']+'\.//;
}
print_columns($dbh, @list);
stmt_ok();

$dbh->disconnect or die "DBI::errstr";

all_ok();
