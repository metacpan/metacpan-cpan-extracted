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

drop qw(person address );
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
  homeaddress_id   integer REFERENCES address(address_id)  ON DELETE CASCADE,
  workaddress_id   integer REFERENCES address(address_id)  ON DELETE CASCADE,
  UNIQUE (fname, lname)
);
EOM
;

my $data = <<EOM
(personset
 (person
  (fname "joe")
  (lname "bloggs")
  (homeaddress
   (address 
    (addressline "1 a street")
    (city "san francisco")))
  (workaddress 
   (address 
    (addressline "23 Z Avenue")
    (city "san francisco"))))
 (person
  (fname "fred")
  (lname "minger")
  (homeaddress 
   (address 
    (addressline "5555 bogging avenue")
    (city "LA")))
  (workaddress 
   (address 
    (addressline "1 blah road")
    (city "LA")))))
EOM
;

my $dbh = connect_to_cleandb();
#DBI->trace(1);

$dbh->do($ddl);

$dbh->mapping([
               Data::Stag->from('sxprstr',
                                '(map (table "person") (col "homeaddress_id") (fktable_alias "homeaddress") (fkcol "address_id") (fktable "address"))'),

               Data::Stag->from('sxprstr',
                                '(map (table "person") (col "workaddress_id") (fktable_alias "workaddress") (fkcol "address_id") (fktable "address"))'),

              ]);

my $personset = Data::Stag->from('sxprstr', $data);
my @persons  = $personset->getnode_person;
foreach (@persons) {
    $dbh->storenode($_);
}

my $query = "SELECT * FROM person INNER JOIN address AS homeaddress ON (person.homeaddress_id = homeaddress.address_id) WHERE fname = 'joe'";
our $NEW_ADDRESS = "some new address";
my $rset = $dbh->selectall_stag($query
                               );
print $rset->sxpr;
my $joe = $rset->getnode_person;
print $joe->sxpr;
my $OLD_ADDRESS = $joe->sgetnode_homeaddress->sgetnode_address->sget_addressline;

$joe->sgetnode_homeaddress->sgetnode_address->set_addressline($NEW_ADDRESS);
$dbh->storenode($joe);
$rset = $dbh->selectall_stag($query
                               );
$joe = $rset->getnode_person;
ok($joe->sgetnode_homeaddress->sgetnode_address->sget_addressline eq $NEW_ADDRESS);

$joe->unset_person_id;
$joe->sgetnode_homeaddress->sgetnode_address->set_addressline($OLD_ADDRESS);

$dbh->storenode($joe);
$rset = $dbh->selectall_stag($query
                               );
$joe = $rset->getnode_person;
ok($joe->sgetnode_homeaddress->sgetnode_address->sget_addressline eq $OLD_ADDRESS);

$dbh->disconnect;
