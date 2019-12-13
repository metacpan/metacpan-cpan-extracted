#!perl -wT

use strict;
use warnings;
use File::Spec;
use Test::Most;

if(not $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval { require Test::Perl::Metrics::Simple; };

if($@) {
	my $msg = 'Test::Perl::Metrics::Simple required to criticise code';
	plan(skip_all => $msg);
}

Test::Perl::Metrics::Simple->import(-complexity => 30);

all_metrics_ok();
