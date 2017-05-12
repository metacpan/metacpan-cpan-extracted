#!/usr/bin/perl
use utf8;
use warnings;
use strict;
use Carp qw(croak);
use lib qw(./perl/lib);
use CGI::Ex::Recipes::Install;

#An install script for CGI::Ex::Recipes application
#For now the commandline mode will be implemented only.
# A web-mode may or may not be implemented
CGI::Ex::Recipes::Install->new->run();

