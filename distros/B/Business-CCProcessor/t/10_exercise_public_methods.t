#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 38;
use Data::Dumper;

use lib qw{lib};
use Business::CCProcessor;

my $cc = Business::CCProcessor->new();
isa_ok($cc,'Business::CCProcessor', "Constructor returned correct object.");

my $fields;
my @methods = ('verisign','paypal','dia');
foreach my $method ('new','button_factory',@methods){
  can_ok('Business::CCProcessor',$method);
}

# my $data = {};
my $data = get_test_cases();
# print '\n\n\n',Dumper($data),'\n\n\n';

$fields = $cc->dia($data);
like($fields->{'action'},qr/dia/,"\$cc->dia() returns correct 'action' value");
is($fields->{'amountOther'}->{'value'},'258.00',"\$cc->dia() returns correct 'amount' value");
is($fields->{'First_Name'}->{'value'},'Testy',"\$cc->dia() returns correct 'fname' value");
is($fields->{'Last_Name'}->{'value'},'Tester',"\$cc->dia() returns correct 'lname' value");
is($fields->{'Street'}->{'value'},'123 Main Street',"\$cc->dia() returns correct 'addr1' value");
is($fields->{'City'}->{'value'},'Decatur',"\$cc->dia() returns correct 'city' value");
is($fields->{'State'}->{'value'},'GA',"\$cc->dia() returns correct 'state' value");
is($fields->{'Zip'}->{'value'},'30033',"\$cc->dia() returns correct 'postal_code' value");
is($fields->{'Phone'}->{'value'},'770-755-1543',"\$cc->dia() returns correct 'phone' value");
is($fields->{'Email'}->{'value'},'hesco@campaignfoundations.com',"\$cc->dia() returns correct 'email' value");


$fields = $cc->verisign($data);
like($fields->{'action'},qr/verisign/,"\$cc->verisign() returns correct 'action' value");
is($fields->{'AMOUNT'}->{'value'},'258.00',"\$cc->verisign() returns correct 'amount' value");
is($fields->{'NAME'}->{'value'},'Testy Tester',"\$cc->verisign() returns correct 'name' value");
is($fields->{'Street'}->{'value'},'123 Main Street',"\$cc->verisign() returns correct 'addr1' value");
is($fields->{'MFCIsapiCommand'}->{'value'},'Orders',"\$cc->verisign() returns correct 'MFCIsapiCommand' value");
is($fields->{'LOGIN'}->{'value'},'calgreens',"\$cc->verisign() returns correct 'login' value");
is($fields->{'TYPE'}->{'value'},'S',"\$cc->verisign() returns correct 'type' value");
like($fields->{'DESCRIPTION'}->{'value'},qr/Donation to Georgia Green Party/,"\$cc->verisign() returns correct 'description' value");
is($fields->{'PARTNER'}->{'value'},'VeriSign',"\$cc->verisign() returns correct 'partner' value");
like($fields->{'COMMENT1'}->{'value'},qr/some comments/,"\$cc->verisign() returns correct 'comments1' value");
like($fields->{'COMMENT2'}->{'value'},qr/some more comments/,"\$cc->verisign() returns correct 'comments2' value");
is($fields->{'button_label'}->{'value'},'Donate Now',"\$cc->verisign() returns correct 'button_value' value");

$fields = $cc->paypal($data);
like($fields->{'action'},qr/paypal/,"\$cc->paypal() returns correct 'action' value");
is($fields->{'amount'}->{'value'},'258.00',"\$cc->paypal() returns correct 'amount' value");
is($fields->{'first_name'}->{'value'},'Testy',"\$cc->paypal() returns correct 'fname' value");
is($fields->{'last_name'}->{'value'},'Tester',"\$cc->paypal() returns correct 'lname' value");
is($fields->{'address1'}->{'value'},'123 Main Street',"\$cc->paypal() returns correct 'addr1' value");
is($fields->{'city'}->{'value'},'Decatur',"\$cc->paypal() returns correct 'city' value");
is($fields->{'state'}->{'value'},'GA',"\$cc->paypal() returns correct 'state' value");
is($fields->{'zip'}->{'value'},'30033',"\$cc->paypal() returns correct 'postal_code' value");
is($fields->{'phn'}->{'value'},'770-755-1543',"\$cc->paypal() returns correct 'phone' value");
is($fields->{'email'}->{'value'},'hesco@campaignfoundations.com',"\$cc->paypal() returns correct 'email' value");

1;

sub get_test_cases {
  my %credit_card_owner = (
         'name' => 'Testy Tester',
        'fname' => 'Testy',
        'lname' => 'Tester',
        'addr1' => '123 Main Street',
        'addr2' => '',
         'city' => 'Decatur',
        'state' => 'GA',
  'postal_code' => '30033',
        'email' => 'hesco@campaignfoundations.com',
        'phone' => '770-755-1543',
     'employer' => 'boss',
   'occupation' => 'work',
       'amount' => '258.00',
    'comments1' => 'These are some comments.',
    'comments2' => 'These are some more comments.',
      );

  my %processor_settings = (
          'action' => 'https://www.paypal.com/cgi-bin/webscr',
        'business' => 'GGPTreasurer@gmail.com',
       'item_name' => 'Georgia Green Party',
          'return' => 'http://www.accegreens.org/gpga/thankyou.php',
   'cancel_return' => 'http://www.accgreens.org/gpga/supporters.cgi',
   'currency_code' => 'USD',
             'on0' => 'Your Employer',
             'on1' => 'Your Occupation',
             'on2' => 'Email',
             'tax' => '0',
     'no_shipping' => '1',
           'login' => 'calgreens',
    'button_label' => 'Donate Now',
    'description' => 'Donation to Georgia Green Party',
     );

  my %data = (
  'processor_settings' => \%processor_settings, 
   'credit_card_owner' => \%credit_card_owner,
    );

  return \%data;
}

