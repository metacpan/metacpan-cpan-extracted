#!/usr/bin/perl

use CGI::MakeItStatic;
use CGI;

my $q = new CGI;
my $check = CGI::MakeItStatic->check($q, {dir => "/tmp/CGI-MakeItStatic"});

print "This will be made static.\n";
print "hoge=". $q->param("hoge"), "\n";
print "month=". $q->param("month"), "\n";

