use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::RingBuffer::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.ring');
close $fh;

{
    my $r = Data::RingBuffer::Shared::Int->new($path, 16);
    $r->write(42);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::RingBuffer::Shared::Int->new($path, 16) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;
