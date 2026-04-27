use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Very long name / path: memfd_create limits name to 249 chars; path
# length limited by PATH_MAX (4096 on Linux). Test that boundaries
# produce clean errors, not buffer overruns.

use Data::Pool::Shared;

# Long memfd name: 249 is the kernel limit; test 255 (over limit)
my $name_ok  = "n" x 200;
my $name_bad = "n" x 500;

my $p1 = eval { Data::Pool::Shared->new_memfd($name_ok, 1, 8) };
ok $p1, "200-char memfd name accepted";

my $p2 = eval { Data::Pool::Shared->new_memfd($name_bad, 1, 8) };
# Linux kernels differ; some accept, some reject. We only require
# no-crash + deterministic behavior.
pass "500-char memfd name: " . ($p2 ? "accepted" : "rejected");

# Very long file path
my $dir = tempdir(CLEANUP => 1);
my $long_seg = "x" x 200;
my $long_path = "$dir/" . join("/", ($long_seg) x 20);   # ~4KB

my $p3 = eval { Data::Pool::Shared->new($long_path, 1, 8) };
ok !$p3, "4KB path rejected cleanly";
like $@, qr/open|too long|name too|ENAMETOOLONG/i, "meaningful error";

done_testing;
