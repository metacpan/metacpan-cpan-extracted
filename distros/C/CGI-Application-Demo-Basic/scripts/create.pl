#!/usr/bin/perl
#
# Name:
#	create.pl.

use strict;
use warnings;

use CGI::Application::Demo::Basic::Util::Create;

# -----------------------------------------------

CGI::Application::Demo::Basic::Util::Create -> new('basic.conf') -> create_all_tables;
