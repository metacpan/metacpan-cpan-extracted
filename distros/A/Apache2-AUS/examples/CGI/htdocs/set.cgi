#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Session::AUS;

my $cgi = CGI->new;
my $aus = CGI::Session::AUS->new;

if(my $set = $cgi->param("set")) {
    $aus->param("set", $set);
}

print $cgi->header("text/plain"), "Hi.\n";
