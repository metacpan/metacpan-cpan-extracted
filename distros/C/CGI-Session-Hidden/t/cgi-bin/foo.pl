#!/usr/bin/perl -w

use strict;
use blib;

use CGI;
use CGI::Session;

my $q = CGI->new;
my $session = CGI::Session->new( "driver:hidden", $q, { CGI => $q } );

my $value = ( $session->param( 'name' ) || 1 ) * 2;
$session->param( 'name' => $value );

print $session->header();

print "<pre>\n";
printf "value=%s\n", $value;
print "</pre>\n";
print "<form action = 'foo.pl' method='post'>\n";
print "<input ", $session->field, " />\n";
print "<input type='submit' name='go' value='Go'></form>\n";
