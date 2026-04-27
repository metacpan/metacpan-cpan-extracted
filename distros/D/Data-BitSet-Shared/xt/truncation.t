use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::BitSet::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.bs');
close $fh;

{
    my $b = Data::BitSet::Shared->new($path, 128);
    $b->set(10);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::BitSet::Shared->new($path, 128) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;
