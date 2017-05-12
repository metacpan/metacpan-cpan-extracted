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
  fname     varchar(255),
  lname     varchar(255),
  UNIQUE (fname, lname)
);
CREATE TABLE person2address (
  address_id   integer REFERENCES address(address_id),
  person_id    integer REFERENCES  person(person_id)
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
   (city "san francisco"))
  (address 
   (addressline "2 b street")
   (city "san francisco"))
 )
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
$dbh->trust_primary_key_values(1);

$dbh->guess_mapping;

my $personset = Data::Stag->from('sxprstr', $data);
$dbh->linking_tables(person2address => [qw(person address)]);
#$dbh->add_linking_tables($personset);
#die $personset->sxpr;                                                         
my @persons  = $personset->getnode_person;
foreach (@persons) {
    $dbh->storenode($_);
}

my @q = ("SELECT person.*, address.* FROM person NATURAL JOIN person2address NATURAL JOIN address WHERE person.fname = 'joe' ORDER BY addressline",
         "(personset(person(address 1)))");
my $rset = $dbh->selectall_stag(@q
                               );
print $rset->sxpr;
my $joe = $rset->getnode_person;
my $first_address = $joe->sgetnode_address;
my $OLD_ADDRESS = $first_address->sget_addressline;
our $NEW_ADDRESS = $OLD_ADDRESS . "; appartment C";

$first_address->set_addressline($NEW_ADDRESS);
print "added appt\n";
print $joe->sxpr, "\n";
$dbh->storenode($joe);
$rset = $dbh->selectall_stag(@q
                            );
$joe = $rset->getnode_person;
my @addresses = $joe->get_address;
ok(@addresses == 2);
ok($joe->sgetnode_address->sget_addressline eq $NEW_ADDRESS);

$joe->unset_person_id;
$joe->sgetnode_address->set_addressline($OLD_ADDRESS);

print "unset person_id\n";
print $joe->sxpr, "\n";
$dbh->storenode($joe);
$rset = $dbh->selectall_stag(@q
                            );
$joe = $rset->getnode_person;
print $joe->sxpr, "\n";
ok($joe->sget_address->sget_addressline eq $OLD_ADDRESS);

$rset = $dbh->selectall_stag(@q
                               );
print $rset->sxpr;
$joe = $rset->getnode_person;
$joe->set_lname('bliggs');
$dbh->storenode($joe);

$rset = $dbh->selectall_stag(@q
                            );
print $rset->sxpr;
ok($rset->get_person->get_lname eq 'bliggs');
$dbh->disconnect;
