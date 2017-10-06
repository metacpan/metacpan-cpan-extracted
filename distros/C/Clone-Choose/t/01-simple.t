#!perl

use strict;
use warnings;
use Test::More;

use Clone::Choose;

my %src = (
    simple => "yeah",
    ary    => [qw(foo bar)],
    hash   => {foo => "bar"}
);

my $tgt = clone(\%src);
is_deeply(\%src, $tgt);

done_testing;
