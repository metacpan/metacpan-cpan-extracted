#!/usr/bin/perl -wT
use strict;
use CGI::Minimal;
use CGI::Imagemap;

my $q = new CGI::Minimal;
my $m = new CGI::Imagemap;

#Load layers of hotspots
foreach( $q->param('map') ){
  /(\w+(?:\.\w+){0,})/;
  $m->addmap(-file=>"maps/$1");
}

#Which was clicked?
my $action = eval{ $m->action($q->param('x'), $q->param('y')) };

#Handle
#For map load a template, and select data from database where $action
if( defined $action ){
  print "Status: 301 FETCH\nLocation: $action\n\n"; }
else{
  print "Status: 204 STAY\n\n";
}
