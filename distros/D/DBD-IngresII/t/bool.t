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

my $testtable = 'asdfdaa';

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

    my $dbh = DBI->connect($dbname, "", "",
		    { AutoCommit => 0, RaiseError => 0, PrintError => 0 })
	or die 'Unable to connect to database!';
    $dbh->{ChopBlanks} = 0;

    return $dbh;
}

my $dbname = get_dbname();

############################
# BEGINNING OF TESTS       #
############################

unless (defined $dbname) {
    plan skip_all => 'DBI_DBNAME and DBI_DSN aren\'t present';
}
else {
    if ($ENV{TEST_BOOLEAN}) {
        plan tests => 21;
    }
    else {
        plan tests => 8;
    }
}

my $dbh = connect_db($dbname);
my $cursor;

ok(($dbh->ing_bool_to_str(undef) eq 'NULL'), 'testing ->ing_bool_to_str(undef)');
ok(($dbh->ing_bool_to_str(0) eq 'FALSE'), 'testing ->ing_bool_to_str(0)');
ok(($dbh->ing_bool_to_str(1) eq 'TRUE'), 'testing ->ing_bool_to_str(1)');

$SIG{__WARN__} = sub {}; # Disable warnings for next test

ok((!defined $dbh->ing_bool_to_str(2)), 'testing ->ing_bool_to_str(2)');

$SIG{__WARN__} = 'DEFAULT';

ok((!defined $dbh->ing_norm_bool(undef)), 'testing ->ing_norm_bool(undef)');
ok(($dbh->ing_norm_bool(3) == 1), 'testing ->ing_norm_bool(3)');
ok(($dbh->ing_norm_bool(0) == 0), 'testing ->ing_norm_bool(0)');
ok(($dbh->ing_norm_bool(-1) == 1), 'testing ->ing_norm_bool(-1)');

unless ($ENV{TEST_BOOLEAN}) {
    $dbh and $dbh->commit;
    $dbh and $dbh->disconnect;
    exit(0);
}

# These tests will fail on pre-10.1 Ingres versions, so they are optional

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

# CREATE TABLE OF APPROPRIATE TYPE
if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable (val BOOLEAN) WITH STRUCTURE=HEAP"), 'Create table (BOOLEAN)');
}
else {
    ok($dbh->do("CREATE TABLE $testtable (val BOOLEAN)"), 'Create table (BOOLEAN)');
}
ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
	  'Insert prepare (BOOLEAN)');
ok($cursor->execute(1), 'Insert execute (BOOLEAN)');
ok($cursor->finish, 'Insert finish (BOOLEAN)');
ok($cursor = $dbh->prepare("SELECT val FROM $testtable WHERE val = ?"), 'Select prepare (BOOLEAN)');
ok($cursor->execute(1), 'Select execute (BOOLEAN)');
my $ar = $cursor->fetchrow_arrayref;
ok($ar && $ar->[0] == 1, 'Select fetch (BOOLEAN)')
	or print STDERR 'Got "' . $ar->[0] . '", expected "' . 1 . "\".\n";
ok($cursor->finish, 'Select finish (BOOLEAN)');
ok($dbh->do("DROP TABLE $testtable"), 'Drop table (BOOLEAN)');


$dbh and $dbh->commit;
$dbh and $dbh->disconnect;

exit(0);
