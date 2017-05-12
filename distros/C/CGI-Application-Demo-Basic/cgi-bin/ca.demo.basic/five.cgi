#!/usr/bin/perl

use local::lib '/home/ron/perl5';
use strict;
use warnings;

use CGI::Application::Demo::Basic::Five;

# -----------------------------------------------

delete @ENV{'BASH_ENV', 'CDPATH', 'ENV', 'IFS', 'PATH', 'SHELL'}; # For security.

CGI::Application::Demo::Basic::Five -> new -> run;
