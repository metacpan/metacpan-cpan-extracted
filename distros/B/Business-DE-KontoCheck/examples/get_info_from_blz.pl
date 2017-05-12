#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Business::DE::KontoCheck;
my $kcheck = Business::DE::KontoCheck->new(
    BLZFILE => "t/testblz.dat",
);
my $konto = $kcheck->get_info_for_blz("10090000");
# $konto is a Business::DE::Konto
my $bankname = $konto->get_bankname;
my $zipcode = $konto->get_zip;
my $bic = $konto->get_bic;
my $method = $konto->get_method;
my $city = $konto->get_location;

print <<"EOM";
Bankname:    $bankname
Zip:         $zipcode
BIC:         $bic
Checkmethod: $method
Location:    $city
EOM
