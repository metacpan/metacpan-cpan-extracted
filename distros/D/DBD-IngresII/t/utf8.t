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

my $testtable = 'asdsdfga';

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
    unless ($ENV{DBI_TEST_UTF8}) {
        plan skip_all => 'DBI_TEST_UTF8 isn\'t present';
        exit 0;
    }
    plan tests => 12;
}

my $dbh = connect_db($dbname);
my($cursor, $str);

eval { local $dbh->{RaiseError}=0;
       local $dbh->{PrintError}=0;
       $dbh->do("DROP TABLE $testtable"); };

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(lol VARCHAR(12)) WITH STRUCTURE=HEAP"),
      'Create table');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(lol VARCHAR(12))"),
      'Create table');
}

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->execute('ąść'), 'Execute INSERT');

$dbh->{ing_enable_utf8} = 0;

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

my $ar = $cursor->fetchrow_hashref;

ok(!utf8::is_utf8($ar->{lol}), 'Check whether string has UTF-8 flag');

$dbh->{ing_enable_utf8} = 1;

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

$ar = $cursor->fetchrow_hashref;

ok(utf8::is_utf8($ar->{lol}), 'Check whether string has UTF-8 flag');

ok(($ar->{lol} eq 'ąść'), 'Check string equality');

ok($cursor->finish, 'Finish cursor');

ok($dbh->do("DROP TABLE $testtable"), 'Drop table');

$dbh and $dbh->commit;
$dbh and $dbh->disconnect;