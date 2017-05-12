#!/usr/bin/perl

# This use lib saves having to install the module repeatedly during testing.

use lib '/home/ron/perl.modules/CGI-Application-Demo-Ajax/lib';
use strict;
use warnings;

use CGI::Application::Demo::Ajax;

# ---------------------

CGI::Application::Demo::Ajax -> new() -> run();
