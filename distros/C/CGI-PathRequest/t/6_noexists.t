use Test::Simple 'no_plan';
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;
use CGI;
use Smart::Comments '###';

$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";





## WHAT IF THESE dont exist

for ( '34fq44q', './house.txt/', 
	'he/ouse.txt', 'demo/.../oake.jpg',
	 'demo/seubdee/../hellokittygif' ) {
   my $rel_path =  $_; ### $_
   my $r = new CGI::PathRequest({ rel_path => $rel_path });
   ok(!$r);
     
}

