use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 2;
}
use DBIx::DBStag;
use DBI;
use Data::Stag;
use FileHandle;

my $ddl = <<EOM
CREATE TABLE person (
  person_id serial NOT NULL PRIMARY KEY,
  fname     varchar(255),
  lname     varchar(255),
  address   varchar(255),
  UNIQUE (fname, lname)
);
EOM
;

my $data = <<EOM
(personset
 (person
  (fname "joe")
  (lname "bloggs")
  (address "1 a street"))
 (person
  (fname "fred")
  (lname "flob")
  (address "23 acacia avenue")))
EOM
;

drop(qw(person));
my $dbh = dbh();
#DBI->trace(1);

$dbh->do(cvtddl($ddl));

my $personset = Data::Stag->from('sxprstr', $data);
my @persons  = $personset->getnode_person;
foreach (@persons) {
    $dbh->storenode($_);
}

our $NEW_ADDRESS = "some new address";
my $rset = $dbh->selectall_stag("SELECT * FROM person WHERE fname = 'joe'",
                               );
my $joe = $rset->getnode_person;
my $OLD_ADDRESS = $joe->get_address;

$joe->set_address($NEW_ADDRESS);
$dbh->storenode($joe);
$rset = $dbh->selectall_stag("SELECT * FROM person WHERE fname = 'joe'",
                               );
$joe = $rset->getnode_person;
ok($joe->sget_address eq $NEW_ADDRESS);

$joe->unset_person_id;
$joe->set_address($OLD_ADDRESS);

$dbh->storenode($joe);
$rset = $dbh->selectall_stag("SELECT * FROM person WHERE fname = 'joe'",
                               );
$joe = $rset->getnode_person;
ok($joe->sget_address eq $OLD_ADDRESS);

$dbh->disconnect;
