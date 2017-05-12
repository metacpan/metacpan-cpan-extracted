#!/usr/bin/perl
#                              -*- Mode: Perl -*- 
# $Basename: import.t $
# $Revision: 1.2 $
# Author          : Ulrich Pfeifer
# Created On      : Sun Jul 12 22:31:12 1998
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Jul 12 22:36:21 1998
# Language        : CPerl
# Update Count    : 5
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1998, Ulrich Pfeifer, all rights reserved.
# 
# 

# The following ist mostly stolen from CGI.pm
BEGIN {$| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::Screen (':standard','-no_debug');
$loaded = 1;
print "ok 1\n";

# Set up a CGI environment
$ENV{REQUEST_METHOD}='GET';
$ENV{QUERY_STRING}  ='game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}     ='/somewhere/else';
$ENV{PATH_TRANSLATED} ='/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}   ='/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT} = 8080;
$ENV{SERVER_NAME} = 'the.good.ship.lollypop.com';

while (<DATA>) {
  print "not " if eval "CGI::$_ ne $_";
  print 'ok ', $.+1, "\n";
}
__DATA__
submit()
submit(-name=>'foo',-value=>'bar')
submit({-name=>'foo',-value=>'bar'})
textfield(-name=>'weather')
textfield(-name=>'weather',-value=>'nice')
textfield(-name=>'weather',-value=>'nice',-override=>1)
checkbox(-name=>'weather',-value=>'nice')
checkbox(-name=>'weather',-value=>'nice',-label=>'forecast')
checkbox(-name=>'weather',-value=>'nice',-label=>'forecast',-checked=>1,-override=>1)
checkbox(-name=>'weather',-value=>'dull',-label=>'forecast')
radio_group(-name=>'game')
radio_group(-name=>'game',-labels=>{'chess'=>'ping pong'})
checkbox_group(-name=>'game',-Values=>[qw/checkers chess cribbage/])
checkbox_group(-name=>'game',-Values=>[qw/checkers chess cribbage/],-Defaults=>['cribbage'],-override=>1)
popup_menu(-name=>'game',-Values=>[qw/checkers chess cribbage/],-Default=>'cribbage',-override=>1)
