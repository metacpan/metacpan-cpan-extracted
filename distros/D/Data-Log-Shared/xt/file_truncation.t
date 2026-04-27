use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Physical file truncation rejection (distinct from the Log module's
# logical `truncate($offset)` API). Ensures validator catches files
# shortened by OS/fs corruption.

use Data::Log::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.log');
close $fh;

{
    my $l = Data::Log::Shared->new($path, 4096);
    $l->append("hi");
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Log::Shared->new($path, 4096) };
ok !$r, "reopen of file-truncated log rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;
