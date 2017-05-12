#!/usr/bin/perl -w

#####################################################################
# throw_browser.cgi - Test program for CGI::Carp::Throw
# Demonstration of output from throw_browser with tracing information
# that includes trace of call into sub {}.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
use CGI::Carp::Throw qw/:carp_browser/;

sub look_for_sub_in_trace {
    throw_browser("quick <b>and</b> easy but no prep");
}

look_for_sub_in_trace;
