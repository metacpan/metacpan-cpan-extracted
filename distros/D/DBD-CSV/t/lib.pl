#!/usr/bin/perl

# lib.pl is the file where database specific things should live,
# wherever possible. For example, you define certain constants
# here and the like.

use strict;
use warnings;

use File::Spec;

my $testname  = "output$$";
my $base_dir  = File::Spec->rel2abs (File::Spec->curdir ());
my $test_dir  = File::Spec->rel2abs ($testname);
my $test_dsn  = $ENV{DBI_DSN}  || "";
   $test_dsn  =~ m/csv/i or $test_dsn = "dbi:CSV:f_dir=$testname";
my $test_user = $ENV{DBI_USER} || "";
my $test_pass = $ENV{DBI_PASS} || "";

DBI->import (":sql_types");
defined &SQL_CHAR    or *SQL_CHAR    = sub {  1 };
defined &SQL_VARCHAR or *SQL_VARCHAR = sub { 12 };
defined &SQL_INTEGER or *SQL_INTEGER = sub {  4 };

sub COL_NULLABLE () { 1 }
sub COL_KEY      () { 2 }

my %v;
{   my @req = qw( DBI SQL::Statement Text::CSV_XS DBD::CSV );
    my $req = join ";\n" => map { qq{require $_;\n\$v{"$_"} = $_->VERSION ()} } @req;
    eval $req;

    if ($@) {
	my @missing = grep { !exists $v{$_} } @req;
	print STDERR "\n\nYOU ARE MISSING REQUIRED MODULES: [ @missing ]\n\n";
	exit 0;
	}
    }

sub AnsiTypeToDb {
    my ($type, $size) = @_;
    my $uctype = uc $type;

    if ($uctype eq "CHAR" || $uctype eq "VARCHAR") {
	$size ||= 1;
	return "$uctype ($size)";
	}

    $uctype eq "BLOB" || $uctype eq "REAL" || $uctype eq "INTEGER" and
	return $uctype;

    $uctype eq "INT" and
	return "INTEGER";

    warn "Unknown type $type\n";
    return $type;
    } # AnsiTypeToDb

# This function generates a table definition based on an input list.  The input
# list consists of references, each reference referring to a single column. The
# column reference consists of column name, type, size and a bitmask of certain
# flags, namely
#
#   COL_NULLABLE - true, if this column may contain NULL's
#   COL_KEY      - true, if this column is part of the table's primary key

sub TableDefinition {
    my ($tablename, @cols) = @_;

    my @keys = ();
    foreach my $col (@cols) {
	$col->[2] & COL_KEY and push @keys, $col->[0];
	}

    my @colDefs;
    foreach my $col (@cols) {
	my $colDef = $col->[0] . " " . AnsiTypeToDb ($col->[1], $col->[2]);
	$col->[3] & COL_NULLABLE or $colDef .= " NOT NULL";
	push @colDefs, $colDef;
	}
    my $keyDef = @keys ? ", PRIMARY KEY (" . join (", ", @keys) . ")" : "";
    my $tq = $tablename =~ m/^\w+\./ ? qq{"$tablename"} : $tablename;
    return sprintf "CREATE TABLE %s (%s%s)", $tq,
	join (", ", @colDefs), $keyDef;
    } # TableDefinition

# This function generates a list of tables associated to a given DSN.
sub ListTables {
    my $dbh = shift or return;

    my @tables = $dbh->func ("list_tables");
    my $msg = $dbh->errstr || $DBI::errstr;
    $msg and die "Cannot create table list: $msg";
    @tables;
    } # ListTables

sub DbCleanup {
    chdir $base_dir;
    -d $testname or return;
    chdir $testname or BAIL_OUT ("Cleanup failed");
    unlink glob "*";
    chdir $base_dir;
    rmdir $testname;
    } # DbCleanup

mkdir $testname, 0755;
END { DbCleanup (); }

# This functions generates a list of possible DSN's aka
# databases and returns a possible table name for a new
# table being created.
#
# Problem is, we have two different situations here: Test scripts
# call us by pasing a dbh, which is fine for most situations.
{   my $listTablesHook;

    my $testtable = "testaa";

    sub FindNewTable
    {
	my $dbh = shift;

	my @tables = defined $listTablesHook ? $listTablesHook->($dbh)
	           : defined &ListTables     ?  ListTables ($dbh)
	           : die "Fatal: ListTables not implemented.\n";

	my $table;
	while (grep { $_ eq $testtable } @tables) {
	    $testtable++;
	    }
	$table = $testtable;
	$testtable++;
	return $table;
	} # FindNewTable
    }

sub isSaneCase {
    my @f = glob "??????.???";
    foreach my $try (qw( FrUbLl BlURgH wOngOs )) {
	my $fn = "$try.csv";
	grep m{^$fn$}i => @f and next;
	open my $fh, ">", $fn or return 1;
	close $fh;
	my $sane = (-f $fn && ! -f lc $fn && ! -f uc $fn);
	unlink $fn;
	return $sane;
	}
    # Assume insane
    return 0;
    } # isSaneCase

sub ServerError {
    die "# Cannot connect: $DBI::errstr\n";
    } # ServerError

sub Connect {
    my $attr = @_ && ref $_[-1] eq "HASH" ? pop @_ : {};
    my ($dsn, $usr, $pass) = @_;
    $dsn  ||= $test_dsn;
    $usr  ||= $test_user;
    $pass ||= $test_pass;
    my $dbh = DBI->connect ($dsn, $usr, $pass, $attr) or ServerError;
    $dbh;
    } # Connect

sub DbDir {
    @_ and $test_dir = File::Spec->catdir ($base_dir, shift);
    $test_dir;
    } # DbDir

sub DbFile {
    my $file = shift or return;
    File::Spec->catdir ($test_dir, $file);
    } # DbFile

1;
