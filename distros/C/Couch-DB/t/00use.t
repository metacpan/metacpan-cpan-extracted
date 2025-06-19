#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions = qw/
	DateTime
	DateTime::Format::ISO8601
	DateTime::Format::Mail
	HTTP::Status
	JSON::XS
	List::Util
	Log::Report
	MIME::Base64
	Mojolicious
	Scalar::Util
	Storable
	URI
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

use_ok 'Couch::DB::Util';
use_ok 'Couch::DB::Row';
use_ok 'Couch::DB::Document';
use_ok 'Couch::DB::Design';
use_ok 'Couch::DB::Result';
use_ok 'Couch::DB::Node';
use_ok 'Couch::DB::Client';
use_ok 'Couch::DB::Cluster';
use_ok 'Couch::DB::Database';
use_ok 'Couch::DB';
use_ok 'Couch::DB::Mojolicious';

done_testing;
