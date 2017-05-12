#!/usr/bin/perl
#
# Name:
# ajax.cgi.
#
# Note:
# Need use lib here because CGI scripts don't have access to
# the PerlSwitches used in httpd.conf.
# Also, it saves having to install the module repeatedly during testing.

use lib '/home/ron/perl.modules/CGI-Application-Demo-Ajax/lib';
use strict;
use warnings;

use CGI::Application::Demo::Ajax;

# ---------------------

CGI::Application::Demo::Ajax -> new() -> run();
