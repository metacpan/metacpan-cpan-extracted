use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Heap::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.heap');
close $fh;

{
    my $h = Data::Heap::Shared->new($path, 16);
    $h->push($_->[0], $_->[1]) for ([5, 100], [1, 200], [3, 300], [7, 400]);
    $h->sync;
}

{
    my $h = Data::Heap::Shared->new($path, 16);
    is $h->size, 4, "size persisted";
    # Pop in priority order (min-heap: 1, 3, 5, 7)
    my @p = $h->pop;
    is $p[0], 1, "smallest first";
    @p = $h->pop;
    is $p[0], 3, "next smallest";
}

done_testing;
