use strict;
use warnings;

use Test::More;

my $script = 'bin/dbioadmin';
ok(-f $script, 'bin/dbioadmin exists');
ok(-x $script, 'bin/dbioadmin is executable');

my $cmd = "$^X -Ilib $script --help 2>&1";
my $out = `$cmd`;
my $rc = $? >> 8;

is($rc, 0, '--help exits with code 0');
like($out, qr/Usage: dbioadmin/, 'help output contains usage banner');
like($out, qr/--mode=MODE/, 'help output mentions upgrade mode');

done_testing;
