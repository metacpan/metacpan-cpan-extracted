#!/usr/bin/perl -w

#####################################################################
# no_err.cgi - Test program for CGI::Carp::Throw
# Demonstrates normal output in presence of eval/throw_browser.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
use CGI::Carp::Throw qw/:carp_browser/;

use Cwd;

my $pwd = getcwd();

print header(), start_html(-title => 'Throw test'), h2("something before $pwd");

eval { throw_browser("quick <b>and</b> easy\n"); };

print h1('some page'), end_html();
