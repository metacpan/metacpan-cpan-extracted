#!/usr/bin/perl -w
use CGI;
use CGI::Session;
my $query = new CGI;
my $sid = $query->param('sessionid');
my $session = new CGI::Session("driver:bitbucket", $sid, {Log=>1});
