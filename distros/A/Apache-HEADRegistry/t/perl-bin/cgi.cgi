#!/usr/bin/perl

use CGI;

my $q = CGI->new;

print $q->header(-type=>'text/plain', -expires=>'+0d'),
      'Hello World';
