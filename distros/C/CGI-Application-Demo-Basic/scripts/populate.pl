#!/usr/bin/perl
#
# Name:
#	populate.pl.

use strict;
use warnings;

use CGI::Application::Demo::Basic::Util::Create;

# ----------------------------

CGI::Application::Demo::Basic::Util::Create -> new('basic.conf') -> populate_all_tables;

