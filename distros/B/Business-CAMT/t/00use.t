#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions = qw/
	XML::LibXML
	Log::Report
	XML::Compile
	XML::Compile::Cache
	JSON
	JSON::XS
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

use_ok 'Business::CAMT::Message';
use_ok 'Business::CAMT';

done_testing;
