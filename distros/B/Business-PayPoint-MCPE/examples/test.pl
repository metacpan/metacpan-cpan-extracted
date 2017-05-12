#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Business::PayPoint::MCPE;
use Data::Dumper;

my $bpm = Business::PayPoint::MCPE->new(
    TestMode => 1,
    InstID => '123456',
);

my %data = $bpm->payment(
    CartID => 654321,
    Desc   => 'description of goods',
    Amount => '10.00',
    Currency => 'GBP',
    CardHolder => 'Joe Bloggs',
    Postcode   => 'BA12BU',
    Email      => 'test@paypoint.net',
    CardNumber => '1234123412341234',
    CV2        => '707',
    ExpiryDate => '0616',
    CardType   => 'VISA',
    Country    => 'GB',
);
print Dumper(\%data);

my $TransID = $data{TransID};
my $SecurityToken = $data{SecurityToken};
# my %data = $bpm->refund(
#     TransID => $TransID,
#     SecurityToken => $SecurityToken,
#     Amount => '5.00',
# );
# print Dumper(\%data);

# my %data = $bpm->repeat(
#     TransID => $TransID,
#     SecurityToken => $SecurityToken,
#     Amount => '5.00',
# );
# print Dumper(\%data);

# my %data = $bpm->capture(
#     TransID => $TransID,
#     SecurityToken => $SecurityToken,
#     Amount => '5.00',
# );
# print Dumper(\%data);

1;