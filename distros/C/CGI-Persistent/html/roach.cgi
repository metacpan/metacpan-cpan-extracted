#!/usr/bin/perl -sI/root/0/PERL/projects/cgipersistence
##
## roach.cgi -- CGI::Persistent example. 
##
## Copyright (c) 1998, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: roach.cgi,v 1.3 1999/04/24 23:32:32 root Exp root $

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Persistent; 

my $rev = '$Id: roach.cgi,v 1.3 1999/04/24 23:32:32 root Exp root $';
$cgi = new CGI::Persistent "dope"; 
print $cgi->header ();
my $self= $cgi->url();
my $u   = $cgi->state_url();
my $cmd = $cgi->param( 'cmd' ); 

print '<b>roach.cgi -- CGI::Persistent Example</b><br><br>';
print 'This form is split across multiple requests. Click on the sections to
feed in the information. The bottom part of this page displays the
persistent attributes associated with this session.<br><br>';
       
print " [ <a href=$u&cmd=name>Name</a> ] ";
print " [ <a href=$u&cmd=address>Address</a> ] ";
print " [ <a href=$u&cmd=email>Email</a> ] ";
print " [ <a href=$u&cmd=web>Web</a> ] ";
print " [ <a href=$u&cmd=voice>Voice</a> ] ";
print " [ <a href=$self>New Session</a> ] ";
print " <br><br> ";

if ( $cmd ) { 

    print $cgi->startform( -method => 'POST', -action => 'roach.cgi' ); 
    print $cgi->state_field(); 
    print $cgi->textfield( -name => $cmd, -size => 42 );
    print $cgi->submit();
    print $cgi->endform();
    $cgi->delete ( 'cmd' );
    
}

print "<br><br><hr>", $cgi->Dump(); 
print "<br>$rev";


