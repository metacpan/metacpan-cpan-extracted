#!/usr/bin/perl
use strict;

use CGI::Application::Tutorial::Namegame;

my $cgiapp = new CGI::Application::Tutorial::Namegame;

$cgiapp->run;

exit;
