#!/usr/bin/perl -w

#####################################################################
# just_cluck.cgi - Test program for CGI::Carp::Throw
# Demonstrates output of cluck with :carp_browser import.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
use CGI::Carp::Throw qw/cluck/;

use Cwd;

sub something_for_cluck_to_trace {
    cluck 'cluck cluck'
}

my $pwd = getcwd();

print header(), start_html(-title => 'Throw test'), h2("something before $pwd");

something_for_cluck_to_trace;

eval { throw_browser("quick <b>and</b> easy\n"); };

print h1('some page'), end_html();
