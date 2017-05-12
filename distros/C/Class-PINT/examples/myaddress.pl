#!/usr/bin/perl -w 

use strict;
use Address;
use Data::Dumper;

my $address = Address->create({
			       StreetNumber => 108,
			       StreetAddress => ['Rose Court','Cross St'],
			       Town=>'Berkhamsted',
			       County=>'Hertfordshire',
			       City=>'Watford',
			      });

#print "id : ", $address->id, "\n";

# warn "city : ", $address->get_City(), "\n";
warn "city : ", $address->City(), "\n";
$address->City('watford1');
warn "city : ", $address->City(), "\n";
$address->city('watford2');
warn "city : ", $address->City(), "\n";

$address->push_StreetAddress('Another Road');

$address->insert_StreetAddress(1,'Yet Another Road');

print $address->StreetNumber, ", '", $address->get_StreetAddress(0), "'\n";
my $i = 1;
while (my $addressline = ($address->StreetAddress)[$i++]) {
    print "$addressline\n";
}
print $address->Town, "\n";
print $address->County, "\n";

# print " flag :  ", $address->Flag, 
#       " is_Flag : ", $address->is_Flag,
#       ' Flag_is_true : ', $address->Flag_is_true,
#       ' Flag_is_false : ', $address->Flag_is_false, 
#       "\n";

# $address->Flag(1);

# print " flag :  ", $address->Flag, 
#       " is_Flag : ", $address->is_Flag,
#       ' Flag_is_true : ', $address->Flag_is_true,
#       ' Flag_is_false : ', $address->Flag_is_false, 
#       "\n";

# $address->Flag(0);

# print " flag :  ", $address->Flag, 
#       " is_Flag : ", $address->is_Flag,
#       ' Flag_is_true : ', $address->Flag_is_true,
#       ' Flag_is_false : ', $address->Flag_is_false, 
#       "\n";

$address->Dictionary(foo=>'bar');

print " Dictionary :  ", $address->Dictionary,
      "\n Dictionary('foo') : ", $address->Dictionary('foo'),
      "\n Dictionary_contains('foo') : ", $address->Dictionary_contains('foo'),
      "\n Dictionary_keys : ", $address->Dictionary_keys,
      "\n Dictionary_values : ", $address->Dictionary_values,
      "\n";

$address->insert_Dictionary(ub=>'40',p=>'45');

print " Dictionary :  ", $address->Dictionary,
      "\n get_Dictionary('ub','p','x') : ", $address->get_Dictionary('ub','p','x'),
      "\n Dictionary_contains('x') : ", $address->Dictionary_contains('x'),
      "\n Dictionary_keys : ", $address->Dictionary_keys,
      "\n Dictionary_values : ", $address->Dictionary_values,
      "\n";

$address->update();
