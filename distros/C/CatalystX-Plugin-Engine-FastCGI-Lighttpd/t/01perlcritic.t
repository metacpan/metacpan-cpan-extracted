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

if ( $ENV{TEST_CRITIC} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    eval {
        my $format = "%l: %m (severity %s)\n";
        if ( $ENV{TEST_VERBOSE} ) {
            $format .= "%p\n%d\n";
        }
        require Test::Perl::Critic;
        Test::Perl::Critic->import( -format => $format, -severity => 1 );
        1;
      }
      or do {
        plan skip_all =>
          'Test::Perl::Critic required for testing PBP compliance';
      };
}
else {
    plan skip_all => 'set TEST_CRITIC for testing PBP compliance';
}

all_critic_ok();
