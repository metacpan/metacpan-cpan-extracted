# -*- cperl -*-

use warnings;
use strict;
use 5.010;

use English qw( -no_match_vars );
use Test::More;

#-----
# The environment variable RELEASE_TESTING should be set to 1 to enable
# this test.
#-----
plan( skip_all => 'Author test' )
    if not $ENV{RELEASE_TESTING};

eval 'use Test::CheckManifest 0.9';
plan( skip_all => 'Test::CheckManifest 0.9 required' )
    if $EVAL_ERROR;

ok_manifest({exclude => [ '/RCS' ]});
