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
    use lib qw(lib);
}
use Test::More tests => 2;

our $WHY_SKIP_SAWAMPERSAND;

BEGIN {
    if ( $ENV{TEST_MATCH_VARS} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
        eval {
            require Devel::SawAmpersand;
            Devel::SawAmpersand->import(qw(sawampersand));
            1;
          }
          or do {
            $WHY_SKIP_SAWAMPERSAND =
              'Devel::SawAmpersand required for testing sawampersand';
          };
    }
    else {
        $WHY_SKIP_SAWAMPERSAND = 'set TEST_MATCH_VARS for testing sawampersand';
    }

    use_ok('CatalystX::Plugin::Engine::FastCGI::Lighttpd');
}

# run sawampersand test if Devel::SawAmpersand is installed.
SKIP: {
    if ($WHY_SKIP_SAWAMPERSAND) {
        skip $WHY_SKIP_SAWAMPERSAND, 1;
    }
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    ok( !sawampersand(), q{$`, $&, and $' should not appear} );
    ## use critic
}
