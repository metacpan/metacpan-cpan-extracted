#!/usr/bin/perl

use local::lib '/home/ron/perl5';
use strict;
use warnings;

use CGI::Application::Demo::Basic::Two;

# -----------------------------------------------

delete @ENV{'BASH_ENV', 'CDPATH', 'ENV', 'IFS', 'PATH', 'SHELL'}; # For security.

CGI::Application::Demo::Basic::Two -> new -> run;
