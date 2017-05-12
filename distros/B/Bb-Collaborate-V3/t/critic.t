#!perl
use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

plan skip_all => 'Author test.  Set $ENV{AUTHOR_TESTING} to a true value to run.'
    unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my $SEVERITY = $ENV{BBC_TEST_CRITICAL_LEVEL} || 4;

Test::Perl::Critic->import(
    -severity => $SEVERITY,
    -verbose => 8,
    -exclude => [qw<Subroutines::ProhibitBuiltinHomonyms Subroutines::RequireArgUnpacking
                    ValuesAndExpressions::ProhibitMixedBooleanOperators>]
    );

all_critic_ok();
