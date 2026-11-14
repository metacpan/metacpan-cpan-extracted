use strict;
use warnings;

use Test::More;
use IPC::Open3 qw(open3);

my $script = 'bin/dbioadmin';
ok(-f $script, 'bin/dbioadmin exists');
SKIP: {
  skip 'MSWin32 has no execute permission bit on files', 1 if $^O eq 'MSWin32';
  ok(-x $script, 'bin/dbioadmin is executable');
}

my $pid = open3(my $in, my $fh, undef, $^X, '-Ilib', $script, '--help');
close $in;
my $out = do { local $/; <$fh> };
waitpid $pid, 0;
my $rc = $? >> 8;

is($rc, 0, '--help exits with code 0');
like($out, qr/Usage: dbioadmin/, 'help output contains usage banner');
like($out, qr/--mode=MODE/, 'help output mentions upgrade mode');
like($out, qr/--all\s+Allow update\/delete without --where/, 'help output mentions --all');

done_testing;
