#!/usr/bin/perl

use CGI;
use Data::Table;
use CGI::Graph;

$q = new CGI;

print $q->header;
print $q->start_html(-title => "Selected Data");

$displayTable = CGI::Graph::table($q->param('source'),$q->param('myFile'),$q->param('X'));
print $displayTable->html;

print $q->end_html;
