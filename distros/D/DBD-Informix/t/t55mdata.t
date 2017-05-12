#!/usr/bin/perl
#
#   @(#)$Id: t55mdata.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test MetaData functions _tables, _columns for DBD::Informix
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2005-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use DBD::Informix::Metadata;
use strict;
use warnings;

if (defined $ENV{DBD_INFORMIX_NO_RESOURCE} && $ENV{DBD_INFORMIX_NO_RESOURCE})
{
    stmt_note "1..0 # Skip: requires RESOURCE privileges but DBD_INFORMIX_NO_RESOURCE set.\n";
    exit 0;
}

print "1..4\n";

# Test connection
my $dbh = connect_to_test_database({ AutoCommit => 1, PrintError => 1 });

my $view = "dbd_ix_view01";
my $private1 = "dbd_ix_private01";
my $private2 = "'informix'.dbd_ix_private02";
my $public1 = "dbd_ix_public01";

# Drop pre-existing versions of views and synonyms (unchecked)
$dbh->{PrintError} = 0;
$dbh->do("DROP VIEW $view");
$dbh->do("DROP SYNONYM $public1");
$dbh->do("DROP SYNONYM $private1");
$dbh->do("DROP SYNONYM $private2");
$dbh->{PrintError} = 1;
stmt_ok();

# Create new views and synonyms
$dbh->do(qq{
CREATE VIEW $view AS
    SELECT T.Owner, T.TabName, T.TabType, C.ColNo, C.ColName
        FROM 'informix'.SysTables T, 'informix'.SysColumns C
        WHERE C.Tabid = T.Tabid}
        )
    or die "DBI::errstr";

# Public and private synonyms were introduced in version 5.00.
# You cannot use PUBLIC or PRIVATE in a MODE ANSI database.
my $public = "PUBLIC";
my $private = "PRIVATE";
if ($dbh->{ix_ModeAnsiDatabase})
{
    $public = "";
    $private = "";
}

$dbh->do("CREATE $public SYNONYM $public1 FOR 'informix'.SysColumns")
    or die "DBI::errstr";
$dbh->do("CREATE $private SYNONYM $private1 FOR 'informix'.SysTables")
    or die "DBI::errstr";
# The next statement only works if you are a DBA.
$dbh->{PrintError} = 0;
$dbh->do("CREATE $private SYNONYM $private2 FOR 'informix'.SysTables");
$dbh->{PrintError} = 1;
stmt_ok();

sub print_tables
{
    my ($dbh, @ctrl) = @_;
    my @list = $dbh->func(@ctrl, '_tables');
    my $pad = ($#ctrl >= 0) ? " " : "";
    print "# Information about @ctrl${pad}tables in database $dbh->{Name}\n";
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
    my $plural = ($#tables >= 0) ? "s" : "";
    {
    local($") = ", ";       # $" is also known as $LIST_SEPARATOR
    print "# Information about columns in table$plural @tables\n";
    }
    my $rowref;
    for $rowref (@list)
    {
        my @row = @{$rowref};
        my $tab = ix_map_tablename($row[0], $row[1]);
        my $nulls = ($row[4] >= 256) ? "N" : "Y";
        $row[4] -= 256 if ($row[4] > 256);
        printf "# %-30s %3d %-18s %s %4d %4d\n", $tab, $row[2], $row[3],
                $nulls, $row[4], $row[5];
    }
}

print "# DBI Version $DBI::VERSION\n";
print "# DBD::Informix version $dbh->{Driver}->{Version}\n";
print "# Database $dbh->{Name}\n";
$dbh->{ChopBlanks} = 1;

# @(#)KLUDGE: Should verify that expected tables are included.
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

# @(#)KLUDGE: should verify that columns are as expected!
print_columns($dbh, $view, $private1, $public1);
stmt_ok();

# Drop views and synonyms (unchecked)
$dbh->{PrintError} = 0;
$dbh->do("DROP VIEW $view");
$dbh->do("DROP SYNONYM $public1");
$dbh->do("DROP SYNONYM $private1");
$dbh->do("DROP SYNONYM $private2");
$dbh->{PrintError} = 1;

$dbh->disconnect or die "DBI::errstr";

all_ok();
