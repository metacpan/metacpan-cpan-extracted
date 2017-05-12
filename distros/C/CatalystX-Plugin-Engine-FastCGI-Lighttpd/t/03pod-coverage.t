#! /usr/bin/env perl
#
# $Id$
#
use strict;
use warnings;
use utf8;
use version; our $VERSION = qv('0.1.0');

BEGIN {
    use File::Spec;
    use FindBin qw($Bin);
    chdir File::Spec->catdir( $Bin, q{..} );
}
use Test::More;

if ( $ENV{TEST_POD} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    eval {
        require Test::Pod::Coverage;
        Test::Pod::Coverage->import;
        my $all_modules = Test::Pod::Coverage->can('all_modules');
        ## no critic (TestingAndDebugging::ProhibitNoWarnings)
        no warnings qw(redefine once);
        ## use critic
        *Test::Pod::Coverage::all_modules = sub {
            my @modules = $all_modules->(@_);
            @modules = grep { !m{^Stickam::Schema}msx } @modules;
            return @modules;
        };
        1;
      }
      or do {
        plan skip_all =>
          'Test::Pod::Coverage required for testing POD coverage';
      };
}
else {
    plan skip_all => 'set TEST_POD for testing POD coverage';
}

all_pod_coverage_ok();
