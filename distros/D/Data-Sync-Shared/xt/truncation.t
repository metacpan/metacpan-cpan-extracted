use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Sync::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.sync');
close $fh;

{
    my $s = Data::Sync::Shared::Semaphore->new($path, 3);
    $s->acquire;
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Sync::Shared::Semaphore->new($path, 3) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small|corrupt/i, "meaningful error";

done_testing;
