#!/usr/bin/perl -w

#####################################################################
# throw_browser_bare.cgi - Test program for CGI::Carp::Throw
# Demonstrate output from throw_browser before printing any HTML.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
use CGI::Carp::Throw;

throw_browser("quick <b>and</b> easy but no prep");

