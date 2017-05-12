use strict;
use warnings;
use utf8;

use Test::More;
use DBD::IngresII;
use DBI qw(:sql_types);

my $testtable = 'testhththt';

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
		    { AutoCommit => 0, RaiseError => 0, PrintError => 0, ShowErrorStatement=>0 })
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
    plan tests => 21;
}

my $dbh = connect_db($dbname);
my $sth;

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable( col1 integer not null primary key, col2 char(2)) WITH STRUCTURE=HEAP"),
      "Create table");
}
else {
    ok($dbh->do("CREATE TABLE $testtable( col1 integer not null primary key, col2 char(2))"),
      "Create table");
}

ok($sth = $dbh->prepare("insert into $testtable values (?,?)"), 'prepare');

ok($sth->bind_param(1,1,SQL_INTEGER), 'bind 1-1');
ok($sth->bind_param(2,'abc',SQL_CHAR), 'bind 1-2');
ok($sth->execute(), 'execute 1');

# use same key now, so an error should raise....
ok($sth->bind_param(1,1,SQL_INTEGER), 'bind 2-1');
ok($sth->bind_param(2,'def',SQL_CHAR), 'bind 2-2');
ok(!$sth->execute(), 'execute 2');

ok($sth->bind_param(1,2,SQL_INTEGER), 'bind 3-1');
ok($sth->bind_param(2,'abc',SQL_CHAR), 'bind 3-2');
ok($sth->execute(), 'execute 3');

# Now check that AutoCommit handling is OK
# AutoCommit is 0:
ok($dbh->{AutoCommit} == 0, 'AutoCommit should be 0');
ok($dbh->{AutoCommit} = 1, 'Set AutoCommit to 1');
#Check that the data from "bind 1" is there
ok($dbh->do("UPDATE $testtable SET col1=4 WHERE col1=1")==1,
    'Updating row (1,\'abc\')');
ok(($dbh->{AutoCommit} = 0)  == 0, 'Set AutoCommit to 0');
#Change the row back again
ok($dbh->do("UPDATE $testtable SET col1=1 WHERE col1=4")==1,
    'Updating row (4,\'abc\')');
# And set rollback-mode
ok($dbh->{ing_rollback}=1, 'Ing_rollback set to 1');
ok($dbh->{AutoCommit} = 1, 'Set AutoCommit to 1');
ok($dbh->do("UPDATE $testtable SET col1=1 WHERE col1=4")==1,
    'Updating row (4,\'abc\') after rollback');

ok($dbh->do( "DROP TABLE $testtable" ), 'Dropping table');
ok($dbh->disconnect(), 'disconnect');