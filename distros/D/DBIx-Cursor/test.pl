# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 10 };
use DBIx::Cursor;
use DBI;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my ($dbh, $c);
my ($ds, $user, $passwd);

$skip = ! defined($ENV{DBI_DS});  # do full testing, when datasource given
$ds = $ENV{DBI_DS} || 'dbi:ExampleP:dir=.';
$user = $ENV{DBI_USER};
$passwd = $ENV{DBI_PASSWD};

skip ($skip, $dbh = DBI->connect($ds));
skip ($skip, $skip || $dbh->do ('
 create table dbixcursor (
   pk1 int not null,
   pk2 int not null,
   ivalue1 int not null,
   ivalue2 int,
   svalue1 varchar(80) not null,
   svalue2 varchar(80),
   primary key (pk1, pk2)
 );'));
skip ($skip, $c = $skip || new DBIx::Cursor($dbh, 'dbixcursor', 'pk1', 'pk2'));
skip ($skip, $skip || $c->set(pk1 => 1, pk2 => 2, ivalue1 => 10, svalue1 => 'hello'));
skip ($skip, $skip || $c->insert);
skip ($skip, $skip || $c->reset);
skip ($skip, $skip || $dbh->do ('drop table dbixcursor'));
skip ($skip, $skip || $dbh->disconnect);
