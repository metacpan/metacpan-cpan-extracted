use strict;
use warnings;
use utf8;

use Test::More;
use DBD::IngresII;

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
    plan tests => 16;
}

my $dbh = connect_db($dbname);
my $event;

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do(qq[
            CREATE TABLE $testtable (
                id INTEGER4,
                name CHAR(64)
            ) WITH STRUCTURE=HEAP
        ]),
        "Testing $testtable table creation"
    );
}
else {
    ok($dbh->do(qq[
            CREATE TABLE $testtable (
                id INTEGER4,
                name CHAR(64)
            )
        ]),
        "Testing $testtable table creation"
    );
}


ok($dbh->do(q[
        CREATE DBEVENT people_update
    ]),
    'Testing people_update event creation'
);

ok($dbh->do(q[
        CREATE PROCEDURE signal_people ( the_id integer4 not NULL ) AS
            DECLARE text VARCHAR(10) not NULL;
            BEGIN
                text = varchar(the_id);
                RAISE DBEVENT people_update text ;
            END
    ]),
    'Testing signal_people procedure creation'
);

ok($dbh->do(qq[
        CREATE RULE people_change
            AFTER INSERT OF $testtable
            EXECUTE PROCEDURE signal_people (the_id = $testtable.id)
    ]),
    'Testing people_change rule creation'
);

ok($dbh->do(q[
        REGISTER DBEVENT people_update
    ]),
    'Testing dbevent people_update registration'
);

ok($dbh->do(qq[
        INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )
    ]),
    "Testing insertion into $testtable"
);


ok($dbh->commit, 'Commiting');

ok(($event = $dbh->func(10, 'get_dbevent')), "Testing \$dbh->func(10, 'get_dbevent')");

ok($dbh->do(qq[
        INSERT INTO $testtable VALUES ( 2, 'Ulrich Pfeifer' )
    ]),
    "Testing insertion into $testtable"
);

ok(($event = $dbh->func('get_dbevent')), "Testing \$dbh->func('get_dbevent')");

# This one should time out
ok(!($event = $dbh->func(10,'get_dbevent')), "Testing \$dbh->func(10, 'get_dbevent')");

ok($dbh->do(q[
        DROP DBEVENT people_update
    ]),
    'Testing  droping people_update dbevent'
);

ok($dbh->do(q[
        DROP RULE people_change
    ]),
    'Testing  droping people_change rule'
);

ok($dbh->do(q[
        DROP PROCEDURE signal_people
    ]),
    'Testing  droping signal_people procedure'
);

ok($dbh->do (qq[
        DROP TABLE $testtable
    ]),
    "Testing  droping $testtable table"
);

ok($dbh->commit, 'Commiting');

$dbh and $dbh->disconnect;