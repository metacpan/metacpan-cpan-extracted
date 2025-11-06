#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions = qw/
	Dancer
	Dancer2
	Log::Report
	Log::Report::Optional
	Log::Report::Lexicon
/;

warn "Perl $]\n";

foreach my $package (sort @show_versions)
{   eval "require $package";

    my $report
      = !$@                    ? "version ". ($package->VERSION || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

if($INC{'Dancer.pm'})
{	use_ok('Dancer::Logger::LogReport');
}
else
{	diag "Dancer(1) is not installed";
}

if($INC{'Dancer2.pm'})
{	use_ok('Dancer2::Logger::LogReport');
	use_ok('Dancer2::Plugin::LogReport::Message');
	use_ok('Dancer2::Plugin::LogReport');
	use_ok('Dancer2::Template::TTLogReport');
}
else
{	diag "Dancer2 is not installed";
}

done_testing;
