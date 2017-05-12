#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

plan skip_all => "No running this one till I can sort out t/perlcriticrc";

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
TODO : {
    local $TODO = "No running this one till I can sort out t/perlcriticrc";
    all_critic_ok();
};
