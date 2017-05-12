#!perl
use strict;
use warnings;
use Test::More tests => 1;
use Carp::REPL 'nodie';

my $repl = \&Carp::REPL::repl;

# I dislike this test, but it's the simplest way to test
isnt($SIG{__DIE__}, $repl, "Carp::REPL nodie didn't overwrite \4SIG{__DIE__}");

