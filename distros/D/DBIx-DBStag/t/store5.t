use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 4;
}
use DBIx::DBStag;
use DBI;
use Data::Stag;
use FileHandle;
use strict;

drop qw( person2address person address );

my $ddl = <<EOM
CREATE TABLE address (
  address_id serial NOT NULL PRIMARY KEY,
  addressline varchar(255),
  city VARCHAR(255)
);
CREATE TABLE person (
  person_id serial NOT NULL PRIMARY KEY,
  fname     varchar(255) NOT NULL,
  lname     varchar(255) NOT NULL,
  job       varchar(255),
  UNIQUE (fname, lname)
);
CREATE TABLE person2address (
  address_id   integer NOT NULL REFERENCES address(address_id),
  person_id    integer NOT NULL REFERENCES  person(person_id)
);
EOM
;

my $data = <<EOM
(set
 (dbstag_metadata
  (link
   (table "person2address")
   (to "person")
   (from "address")))
 (person
  (fname "sherlock")
  (lname "holmes")
  (job "detective"))
 (person
  (fname "immanuel")
  (lname "kant")
  (job "philosopher"))
 (person
  (fname "charles")
  (lname "darwin")
  (job "naturalist"))
 (person
  (fname "winston")
  (lname "churchill")
  (job "prime minister"))
 (person
  (fname "clement")
  (lname "attlee")
  (job "prime minister"))
 (person
  (fname "buck")
  (lname "rogers")
  (job "space pilot"))
 (address 
  (addressline "1 A street")
  (city "london"))
 (address 
  (addressline "221B Baker Street")
  (city "london")
  (person
   (fname "sherlock")
   (lname "holmes"))
  (person
   (fname "dr")
   (lname "watson")))
 (address
  (addressline "10 Downing Street")
  (city "london")
  (person
   (fname "winston")
   (lname "churchill"))
  (person
   (fname "clement")
   (lname "attlee")))
 )
EOM
;

my $dbh = connect_to_cleandb();

# this time we are storing mapping data in dbstag_metadata in data

$dbh->do($ddl);
my $set = Data::Stag->from('sxprstr', $data);
my @nodes  = $set->kids;
$dbh->is_caching_on('person',1);
foreach (@nodes) {
    $dbh->storenode($_);
}
my $aset =
  $dbh->selectall_stag("SELECT address.*, person.* FROM address NATURAL JOIN person2address NATURAL JOIN person WHERE addressline = '10 Downing Street'");
print $aset->xml;
my @addresses = $aset->get_address;
ok(@addresses==1);
my $address = shift @addresses;
my @persons = $address->get_person;
ok(@persons==2);
ok(grep {$_->get_lname eq "attlee"} @persons);
ok(grep {$_->get_lname eq "churchill"} @persons);
$dbh->disconnect;
