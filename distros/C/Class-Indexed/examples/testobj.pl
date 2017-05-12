#!/usr/bin/perl -w

use strict;

use testclass;

warn "getting object \n";
# create test object
my $object = testclass->new(
			    'Pub_ID' => 43,'Pub_Name'=> 'The Crystal Palace',
			    'Pub_Description'=>'Large Pub near the Canal and the Berkhamsted Station',
			    'Brewery_ID'=> 3, 'Town_ID'=> 7,
			    'County_ID'=> 1,  'PubType_ID'=> 2 ,
			    'Pub_Street'=> 'Station Road',  'Pub_Address'=> 'Berkhamsted, Hertfordshire', 
			    'Pub_Postcode'=> 'HP4 6GA',  'Pub_Telephone'=> '23 2132432',  
);

warn "storing object \n";
$object->Store();

# index test object
warn "indexing obect\n";

$object->Index();


