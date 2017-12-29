#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use CGI::Application::Bouquet::Rose; # For the version #.

use Test::More;

use Carp;
use Config::IniFiles;
use File::Copy;
use File::Path;
use File::Spec;
use Getopt::Long;
use HTML::Template;
use Moo;
use Pod::Usage;
use strict;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Carp
	Config::IniFiles
	File::Copy
	File::Path
	File::Spec
	Getopt::Long
	HTML::Template
	Moo
	Pod::Usage
	strict
	Types::Standard
	warnings
/;

diag "Testing CGI::Application::Bouquet::Rose V $CGI::Application::Bouquet::Rose::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
