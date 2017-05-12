#!/usr/bin/perl -w

use strict;
use CGI; 
use JSON;
use Data::Dumper;

my $q = new CGI;


print $q->header(); 


my $val = $q->param('args');
my @vals = split(//, $val);


my $hash;
map { $hash->{$_} = chr(ord($_)+1) } @vals;

my $json = objToJson($hash);

print "var jsonObj = $json";
