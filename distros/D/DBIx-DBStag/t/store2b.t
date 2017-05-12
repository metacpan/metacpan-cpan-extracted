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

drop qw( person address);
my $ddl = <<EOM
CREATE TABLE address (
  address_id serial NOT NULL PRIMARY KEY,
  addressline varchar(255),
  city VARCHAR(255)
);
CREATE TABLE person (
  person_id serial NOT NULL PRIMARY KEY,
  fname     varchar(255),
  lname     varchar(255),
  address_id   integer REFERENCES address(address_id)  ON DELETE CASCADE,
  UNIQUE (fname, lname)
);
EOM
;

my $data = <<EOM
(personset
 (person
  (fname "joe")
  (lname "bloggs")
  (address 
   (addressline "1 a street")
   (city "san francisco")))
 (person
  (fname "fred")
  (lname "minger")
  (address 
   (addressline "5555 bogging avenue")
   (city "LA"))))
EOM
;

my $dbh = connect_to_cleandb();
#DBI->trace(1);

$dbh->do($ddl);

$dbh->guess_mapping;
my $personset = Data::Stag->from('sxprstr', $data);
my @persons  = $personset->getnode_person;
foreach (@persons) {
    $dbh->storenode($_);
}

our $NEW_ADDRESS = "some new address";
my $rset = $dbh->selectall_stag("SELECT * FROM person NATURAL JOIN address WHERE fname = 'joe'",
                               );
print $rset->sxpr;
my $joe = $rset->getnode_person;
my $OLD_ADDRESS = $joe->sgetnode_address->sget_addressline;

$joe->sgetnode_address->set_addressline($NEW_ADDRESS);
$dbh->storenode($joe);
$rset = $dbh->selectall_stag("SELECT * FROM person NATURAL JOIN address WHERE fname = 'joe'",
                               );
$joe = $rset->getnode_person;
ok($joe->sgetnode_address->sget_addressline eq $NEW_ADDRESS);

$joe->unset_person_id;
$joe->sgetnode_address->set_addressline($OLD_ADDRESS);

$dbh->storenode($joe);
$rset = $dbh->selectall_stag("SELECT * FROM person NATURAL JOIN address WHERE fname = 'joe'",
                               );
$joe = $rset->getnode_person;
ok($joe->sgetnode_address->sget_addressline eq $OLD_ADDRESS);

$dbh->disconnect;
