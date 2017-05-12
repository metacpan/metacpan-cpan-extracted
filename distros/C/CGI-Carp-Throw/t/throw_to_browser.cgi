#!/usr/bin/perl -w

#####################################################################
# throw_browser.cgi - Test program for CGI::Carp::Throw
# Basic demonstration of output from throw_browser.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
use CGI::Carp::Throw;

print header(), start_html(-title => 'Throw test'), h2("something before zz");

throw_browser("quick <b>and</b> easy");

print h1('some page'), end_html();
