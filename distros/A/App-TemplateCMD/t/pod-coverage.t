#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
    plan( skip_all => $msg );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

pod_coverage_ok('App::TemplateCMD'                   );
pod_coverage_ok('App::TemplateCMD::Command'          );
pod_coverage_ok('App::TemplateCMD::Command::Cat'     );
pod_coverage_ok('App::TemplateCMD::Command::Print'   );
pod_coverage_ok('App::TemplateCMD::Command::Describe');
pod_coverage_ok('App::TemplateCMD::Command::Build'   );
pod_coverage_ok('App::TemplateCMD::Command::Help'    );
pod_coverage_ok('App::TemplateCMD::Command::List'    );
pod_coverage_ok('App::TemplateCMD::Command::Conf'    );
done_testing();
