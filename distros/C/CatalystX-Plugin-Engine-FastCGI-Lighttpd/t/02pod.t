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
        require Test::Pod;
        Test::Pod->import;
        1;
      }
      or do {
        plan skip_all => 'Test::Pod required for testing POD';
      };
}
else {
    plan skip_all => 'set TEST_POD for testing POD';
}

all_pod_files_ok();
