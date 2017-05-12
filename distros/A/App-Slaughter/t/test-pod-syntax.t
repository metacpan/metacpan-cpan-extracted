#!/usr/bin/perl -w

#
#  Test that the POD we use in our modules is valid.
#


use strict;
use Test::More;

my $eval = "use Test::Pod 1.00";
## no critic (Eval)
eval($eval);
## use critic
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

#
#  Run the test(s).
#
my @poddirs;
if ( -d "bin/" && -d "lib/" && -d "t/" )
{
    @poddirs = qw( bin lib t );
}
elsif ( -d "../bin/" && -d "../lib" && -d "../t" )
{
    @poddirs = qw( ../bin ../lib ../t );
}


all_pod_files_ok( all_pod_files(@poddirs) );
