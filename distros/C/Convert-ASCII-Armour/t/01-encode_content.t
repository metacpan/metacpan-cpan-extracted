#!/usr/bin/perl -sw
##
## 01-encode_content.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 01-encode_content.t,v 1.1.1.1 2001/03/18 07:27:39 vipul Exp $

use lib '../lib';
use Convert::ASCII::Armour;
use Data::Dumper;

print "1..5\n";
my $i = 0;
my $converter = new Convert::ASCII::Armour;

my %data = ( Message  => "This is a message",
             Number   => "8989323", 
             Date     => "13 March, 2001",
             Longline => "abcdefghijklmnopqrstuvwxyz\
                          ABCDEFGHIJKLMNOPQRSTUVWZYZ\ 
                          123456789\
                          ~!@#$%^&*()-_=+[{]}\|"
           );

my $encoded = $converter->encode_content (%data);
print "$encoded\n";
print $encoded ? "ok " : "not ok "; print ++$i . "\n";

my $data = $converter->decode_content ($encoded);

print $data{Longline} eq $$data{Longline} ? "ok " : "not ok "; print ++$i . "\n";
print $data{Number} eq $$data{Number} ? "ok " : "not ok "; print ++$i . "\n";
print $data{Date} eq $$data{Date} ? "ok " : "not ok "; print ++$i . "\n";
print $data{Message} eq $$data{Message} ? "ok " : "not ok "; print ++$i . "\n";
