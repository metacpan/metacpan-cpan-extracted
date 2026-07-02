use strict;
use warnings;
use Test::More;
use FindBin;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

for my $eg (sort glob "$FindBin::Bin/../eg/*.pl") {
    my $out = `$^X -Mblib $eg 2>&1`;
    is $?, 0, "$eg exits 0" or diag $out;
}

done_testing;
