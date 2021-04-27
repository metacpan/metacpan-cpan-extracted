#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use CGI::Session::ExpireSessions; # For the version #.

use Test::More;

use Carp;
use CGI::Session;
use File::Spec;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Carp
	CGI::Session
	File::Spec
/;

diag "Testing CGI::Session::ExpireSessions V $CGI::Session::ExpireSessions::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
