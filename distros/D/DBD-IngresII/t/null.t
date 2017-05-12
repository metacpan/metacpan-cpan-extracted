# Copyright (c) 2013, 2014 Tomasz Konojacki
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;
use utf8;

use Test::More;
use DBD::IngresII;
use DBI qw(:sql_types);
use Encode;

my $testtable = 'asdsdfgza';

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

my $dbname = get_dbname();

############################
# BEGINNING OF TESTS       #
############################

unless (defined $dbname) {
    plan skip_all => 'DBI_DBNAME and DBI_DSN aren\'t present';
}
else {
    plan tests => 55;
}

my $dbh = connect_db($dbname);
my($cursor, $str);

eval { local $dbh->{RaiseError}=0;
       local $dbh->{PrintError}=0;
       $dbh->do("DROP TABLE $testtable"); };

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(lol VARCHAR(12)) WITH STRUCTURE=HEAP"),
      'CREATE TABLE');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(lol VARCHAR(12))"),
      'CREATE TABLE');
}

$dbh->{ing_empty_isnull} = 0;

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->execute(''), 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok((my $ar = $cursor->fetchrow_hashref), 'Fetch row');

ok(((defined $ar->{lol}) && ($ar->{lol} eq '')), 'Check whether string is empty');

ok($dbh->do(qq{DELETE FROM $testtable WHERE lol = ''}), 'DELETE row');

$dbh->{ing_empty_isnull} = 1;

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->execute(''), 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok(($ar = $cursor->fetchrow_hashref), 'Fetch row');

ok((!defined $ar->{lol}), 'Check whether returned value is NULL');

ok($dbh->do("DELETE FROM $testtable WHERE lol IS NULL"), 'DELETE row');

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)", {ing_empty_isnull => 0}),
      'Prepare INSERT');

ok($cursor->execute(''), 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok(($ar = $cursor->fetchrow_hashref), 'Fetch row');

ok(((defined $ar->{lol}) && ($ar->{lol} eq '')), 'Check whether string is empty');

ok($cursor->finish, 'Finish cursor');

ok($dbh->do("DROP TABLE $testtable"), 'DROP TABLE');

#

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(lol INT4) WITH STRUCTURE=HEAP"),
      'CREATE TABLE');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(lol INT4)"),
      'CREATE TABLE');
}

$dbh->{ing_empty_isnull} = 0;

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

{
    no warnings;
    ok($cursor->bind_param(1, '', {TYPE => SQL_INTEGER}), 'bind_param');
}

ok($cursor->execute, 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok(($ar = $cursor->fetchrow_hashref), 'Fetch row');

ok(((defined $ar->{lol}) && ($ar->{lol} == 0)), 'Check whether int equals 0');

ok($dbh->do("DELETE FROM $testtable WHERE lol = 0"), 'DELETE row');

$dbh->{ing_empty_isnull} = 1;

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

{
    no warnings;
    ok($cursor->bind_param(1, '', { TYPE => SQL_INTEGER }), 'bind_param');
}

ok($cursor->execute, 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok(($ar = $cursor->fetchrow_hashref), 'Fetch row');

ok((!defined $ar->{lol}), 'Check whether int is NULL');

ok($dbh->do("DELETE FROM $testtable WHERE lol IS NULL"), 'DELETE row');

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->execute("124"), 'Execute INSERT with PV which looks like number');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok(($ar = $cursor->fetchrow_hashref), 'Fetch row');

ok($ar->{lol} == 124, 'Check whether int is equal to 124');

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->bind_param_array(1, 1, SQL_INTEGER), 'bind_param_array, it used to crash');

ok($cursor->finish, 'finish INSERT cursor');

ok($dbh->do("DROP TABLE $testtable"), 'DROP TABLE');

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(abc FLOAT) WITH STRUCTURE=HEAP"),
      'CREATE TABLE');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(abc FLOAT)"),
      'CREATE TABLE');
}

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->bind_param_array(1, 1.1, SQL_DOUBLE), 'bind_param_array, it used to crash');

ok($cursor->finish, 'finish INSERT cursor');

ok($dbh->do("DROP TABLE $testtable"), 'DROP TABLE');

$dbh and $dbh->commit;
$dbh and $dbh->disconnect;