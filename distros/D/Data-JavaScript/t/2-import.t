#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;
use Test2::Tools::Subtest qw/subtest_buffered/;

use Data::JavaScript qw(:all);

subtest_buffered private_quotemeta => sub {
  # We're verifying that a newline is quoted.
  is
    __quotemeta( "Hello World\n" ),
    q/Hello World\n/, ## no critic (RequireInterpolationOfMetachars)
    'Simple __quotemeta()';
};

subtest_buffered jsdump => sub {
  is
    join( q//, jsdump( 'narf', 'Troz!' ) ),
    'var narf = "Troz!";',
    'Simple jsdump()';
};

done_testing;
