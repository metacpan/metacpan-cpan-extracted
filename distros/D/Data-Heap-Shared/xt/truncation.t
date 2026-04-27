use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Heap::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.heap');
close $fh;

{
    my $h = Data::Heap::Shared->new($path, 16);
    $h->push(1, 100);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Heap::Shared->new($path, 16) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;
