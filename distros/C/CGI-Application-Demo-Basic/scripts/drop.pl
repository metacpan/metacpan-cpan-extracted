#!/usr/bin/perl
#
# Name:
#	drop.pl.

use strict;
use warnings;

use CGI::Application::Demo::Basic::Util::Create;

# -----------------------------------------------

CGI::Application::Demo::Basic::Util::Create -> new('basic.conf') -> drop_all_tables;
