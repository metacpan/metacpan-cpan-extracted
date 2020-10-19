#!perl

use strict;
use warnings;
use Test::More 0.98;

use Devel::CheckOS;

my @platforms = Devel::CheckOS::list_platforms();
diag "list_platforms(): ", explain(\@platforms);

for my $platform (@platforms) {
    diag "os_is($platform): ", Devel::CheckOS::os_is($platform) ? 1:0;
}

ok 1;
done_testing;
