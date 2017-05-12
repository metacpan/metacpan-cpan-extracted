# Copyright (c) 2012, 2013 Tomasz Konojacki
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;
use utf8;

use Test::More;
use DBD::IngresII;
use DBI;
use Encode;

my $testtable = 'asda';

sub get_dbname {
    # find the name of a database on which test are to be performed
    my $dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN};
    if (defined $dbname && $dbname !~ /^dbi:IngresII/) {
	    $dbname = "dbi:IngresII:$dbname";
    }
    return $dbname;
}

sub connect_db {
    # Connects to the database.
    # If this fails everything else is in vain!
    my ($dbname) = @_;
    $ENV{II_DATE_FORMAT}='SWEDEN';       # yyyy-mm-dd

    my $dbh = DBI->connect($dbname, '', '',
		    { AutoCommit => 0, RaiseError => 0, PrintError => 1, ShowErrorStatement=>1 })
	or die 'Unable to connect to database!';
    $dbh->{ChopBlanks} = 0;

    return $dbh;
}

sub get_charset {
    my %charsets = (
        UTF8    => 'utf-8',
        WIN1250 => 'cp1250'
    );

    unless (defined $ENV{DBI_CHARSET}) {
        return 'utf-8';
    }

    unless (defined $charsets{$ENV{DBI_CHARSET}}) {
        die "Unknown charset passed: '$ENV{DBI_CHARSET}'";
    }

    return $charsets{$ENV{DBI_CHARSET}};
}

sub get_data_for_charset {
    my $charset = shift;

    my %data = (
        'utf-8' => 'ąść',
        win1250 => 'ąść'
    );

    unless (defined $data{$charset}) {
        die "No data for charset '$charset'";
    }

    return $data{$charset};
}

my $dbname = get_dbname();

############################
# BEGINNING OF TESTS       #
############################

unless (defined $dbname) {
    plan skip_all => 'DBI_DBNAME and DBI_DSN aren\'t present';
}
elsif (5.010_000 > $]) {
    plan skip_all => 'This test would fail in perl 5.8.x';
}
else {
    unless ($ENV{TEST_NCHAR} || $ENV{DBI_TEST_NCHAR}) {
        plan skip_all => 'DBI_TEST_NCHAR isn\'t present';
        exit 0;
    }
    plan tests => 22;
}

my $dbh = connect_db($dbname);
my $charset = get_charset();
my $cursor;

#
# Table creation/destruction.  Can't do much else if this isn't working.
#
eval { local $dbh->{RaiseError}=0;
       local $dbh->{PrintError}=0;
       $dbh->do("DROP TABLE $testtable"); };
if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64)) WITH STRUCTURE=HEAP"),
                'Basic create table');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64))"),
                'Basic create table');
}
ok($dbh->do("INSERT INTO $testtable VALUES(1, 'Alligator Descartes')"),
      'Basic insert(value)');
ok($dbh->do("DELETE FROM $testtable WHERE id = 1"),
      'Basic Delete');
ok($dbh->do( "DROP TABLE $testtable" ),
      'Basic drop table');

my $data = get_data_for_charset($charset);


# CREATE TABLE OF APPROPRIATE TYPE
if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable (val NCHAR(10)) WITH STRUCTURE=HEAP"), 'Create table (NCHAR)');
}
else {
    ok($dbh->do("CREATE TABLE $testtable (val NCHAR(10))"), 'Create table (NCHAR)');
}

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
	  'Insert prepare (NCHAR)');
ok($cursor->execute($data), 'Insert execute (NCHAR)');
ok($cursor->finish, 'Insert finish (NCHAR)');
ok($cursor = $dbh->prepare("SELECT val FROM $testtable"), 'Select prepare (NCHAR)');
ok($cursor->execute, 'Select execute (NCHAR)');
my $ar = $cursor->fetchrow_arrayref;
ok($ar && decode('utf-16le', $ar->[0]) eq ($data . (' ' x (10 - (length $data)))), 'Select fetch (NCHAR)')
	or print STDERR 'Got "' . encode('utf-8', decode('utf-16le', $ar->[0])) . '", expected "' . encode('utf-8', $data . (' ' x (10 - (length $data)))) . "\".\n";
ok($cursor->finish, 'Select finish (NCHAR)');
ok($dbh->do("DROP TABLE $testtable"), 'Drop table (NCHAR)');

# CREATE TABLE OF APPROPRIATE TYPE
if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable (val NVARCHAR(10)) WITH STRUCTURE=HEAP"), 'Create table (NVARCHAR)');
}
else {
    ok($dbh->do("CREATE TABLE $testtable (val NVARCHAR(10))"), 'Create table (NVARCHAR)');
}

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
	  'Insert prepare (NVARCHAR)');
ok($cursor->execute($data), 'Insert execute (NVARCHAR)');
ok($cursor->finish, 'Insert finish (NVARCHAR)');
ok($cursor = $dbh->prepare("SELECT val FROM $testtable"), 'Select prepare (NVARCHAR)');
ok($cursor->execute, 'Select execute (NVARCHAR)');
$ar = $cursor->fetchrow_arrayref;
ok($ar && $ar->[0] eq encode('utf-16le', $data), 'Select fetch (NCHAR)')
	or print STDERR 'Got "' . encode('utf-8', decode('utf-16le', $ar->[0])) . '", expected "' . encode('utf-8', $data) . "\".\n";
ok($cursor->finish, 'Select finish (NVARCHAR)');
ok($dbh->do("DROP TABLE $testtable"), 'Drop table (NVARCHAR)');

$dbh and $dbh->commit;
$dbh and $dbh->disconnect;

exit(0);