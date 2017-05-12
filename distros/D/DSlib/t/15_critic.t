#!/usr/bin/perl

# ########################################################################## #
# Title:         Static linting of source
# Creation date: 2007-04-29
# Author:        Michael Zedeler
# Description:   Runs lint tests of all perl files
# File:          $Source: /data/cvs/lib/DSlib/t/15_critic.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    plan( skip_all => <<'END_MESSAGE' );
Perlcritic tests are only relevant if you are doing regression tests after modifying this module. Set $ENV{TEST_AUTHOR} to a true value to run them.
END_MESSAGE
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
  