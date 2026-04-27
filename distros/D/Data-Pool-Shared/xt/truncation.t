use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# new_from_fd / reopen must reject a file that has been truncated
# mid-structure (header claims more bytes than file contains).

use Data::Pool::Shared;

# 1. Legitimate file, then truncate by 1 byte → total_size mismatch rejected
my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pool');
close $fh;

my $p = Data::Pool::Shared::I64->new($path, 8);
ok $p, "created file-backed pool";
undef $p;

my $sz = -s $path;
ok $sz > 128, "file size $sz > header";
truncate($path, $sz - 1) or die "truncate: $!";

my $err;
my $p2 = eval { Data::Pool::Shared::I64->new($path, 8) };
$err = $@ unless $p2;
ok !$p2, "reopen of truncated file rejected";
like $err, qr/invalid|incompatible|too small/i, "meaningful error";

# 2. Open the (truncated) file via new_from_fd also rejected
truncate($path, $sz);    # restore for clean new_from_fd test
my $p3 = Data::Pool::Shared::I64->new($path, 8);
my $p3_fd;
{
    open(my $fh2, '<', $path) or die "open: $!";
    $p3_fd = fileno($fh2);

    truncate($path, $sz - 8) or die;
    my $r = eval { Data::Pool::Shared::I64->new_from_fd($p3_fd) };
    ok !$r, "new_from_fd on truncated file rejected";
}

done_testing;
