use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::RingBuffer::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.ring');
close $fh;

{
    my $r = Data::RingBuffer::Shared::Int->new($path, 16);
    $r->write($_) for 1..5;
    $r->sync;
}

{
    my $r = Data::RingBuffer::Shared::Int->new($path, 16);
    is $r->latest, 5, "latest persisted";
    is $r->latest(0), 5, "latest(0)";
    is $r->latest(4), 1, "latest(4) (oldest in last 5)";
}

done_testing;
