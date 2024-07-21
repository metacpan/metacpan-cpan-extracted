use v5.40;
use Test2::V0;

my $exit = system $^X, "-c", "script/perl-gzip-script";
is $exit, 0;

done_testing;
