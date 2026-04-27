use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(:mode);

# Umask compliance: when creating a file-backed pool, the resulting
# file permissions must respect the process umask. A module that
# passes literal 0666 to open() bypasses umask, exposing IPC files
# to other users.

use Data::Pool::Shared;

my $dir = tempdir(CLEANUP => 1);

# Set restrictive umask: owner-only
my $old_umask = umask 0077;

my $path = "$dir/umask.pool";
my $p = Data::Pool::Shared::I64->new($path, 8);
undef $p;

umask $old_umask;

ok -f $path, "file created";
my @st = stat $path;
my $mode = $st[2] & 07777;
diag sprintf "mode = 0%o", $mode;

# With umask 0077, effective mode should be 0600 (no group/other)
is $mode & 0077, 0, "group/other bits masked off (umask respected)";
ok $mode & 0600, "owner has read+write";

done_testing;
