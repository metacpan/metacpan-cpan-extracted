use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Queue::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.q');
close $fh;

{
    my $q = Data::Queue::Shared::Int->new($path, 16);
    $q->push(42);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Queue::Shared::Int->new($path, 16) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;
