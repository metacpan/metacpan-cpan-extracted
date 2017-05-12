#!/usr/bin/perl

use strict;
use warnings;

use CGI::Application::Demo::Basic::Util::Config;

# -----------------------------------------------

my($config) = CGI::Application::Demo::Basic::Util::Config -> new('basic.conf') -> config;

print map{"$_ => $$config{$_}\n"} sort keys %$config;
