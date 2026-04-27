use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Deque::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.deque');
close $fh;

{
    my $d = Data::Deque::Shared::Int->new($path, 16);
    $d->push_back(42);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Deque::Shared::Int->new($path, 16) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;
