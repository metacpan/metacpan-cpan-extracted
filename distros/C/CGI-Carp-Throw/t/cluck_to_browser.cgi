#!/usr/bin/perl -w

#####################################################################
# cluck_to_browser.cgi - Test program for CGI::Carp::Throw
# Demonstrates output of cluck with :carp_browser import.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
# use CGI::Carp qw/warningsToBrowser/;
use CGI::Carp::Throw qw/:carp_browser cluck/;
#use CGI::Carp::Throw;

print header(), start_html(-title => 'Throw test'), h2("something before");

cluck "really warn - ok just a <b>message</b>";

print h1('some page'), end_html();
