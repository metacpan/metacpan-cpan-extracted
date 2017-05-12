#!/usr/bin/perl

use Test::More tests => 1;
use_ok("Calendar::Schedule", ':all');

# #example3 start
# #use Calendar::Schedule;
# $TTable = Calendar::Schedule->new();
# $TTable->{'ColLabel'} = "%A";
# $TTable->add_entries(<<EOT
# 
# Mon 15:30-16:30 Teaching (CSCI 3136)
# Tue 10-11:30 Teaching (ECMM 6014)
# Wed 13:30-14:30 DNLP
# Wed 15:30-16:30 Teaching (CSCI 3136) :until Apr 8, 2005
# Thu 10-11:30 Teaching (ECMM 6014)
# Thu 16-17 WIFL
# Fri 14:30-15:30 MALNIS
# Fri 15:30-16:30 Teaching (CSCI 3136)
# Wed 15-16 meeting
# Wed 15:30-18 another meeting
# 
# EOT
# );
# $out = "<p>\n" . $TTable->generate_table();
# print $out;
# #example3 end
