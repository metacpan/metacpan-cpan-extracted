#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::Require::Module qw< Test::Perl::Critic >;
use Test::Perl::Critic;

my $EXE = 'bin';

my @FILES = (
    qw<
        Makefile.PL
        lib
        t
        xt
    >
);

push @FILES, $EXE if -e $EXE && -d $EXE;

all_critic_ok(@FILES);
