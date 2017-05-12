#!/usr/bin/perl -w 

use strict;
use Address;
use Data::Dumper;

warn "adding addresses\n";
my $address1 = Address->create({
    StreetNumber => 10,
    StreetAddress => 'Church Street',
    Town=>'Berkhamsted',
    County=>'Hertfordshire',
    City=>'Hemmel Hampstead',
});

my $address2 = Address->create({
			       StreetNumber => 108,
			       StreetAddress => 'Charles Street',
			       Town=>'Berkhamsted',
			       County=>'Hertfordshire',
			       City=>'Watford',
			      });

warn "getting addresses in watford\n";

foreach my $address (Address->search(City=>'Watford')) {
    print "id : ", $address->id, "\n",
    join(', ',
	 $address->StreetNumber,
	 $address->Town,
	 $address->County,
	 $address->City
	 ), "\n";
    warn Dumper(_data_hash=>$address->_data_hash);
}
