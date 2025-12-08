use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;

use lib '.';
use t::Util;

is(run()->status, 2, 'no arg');
is(run('--version')->status, 0, '--version');

is(run('-Mup --version')->status, 0, '-Mup --version');
is(run('-Mup --no-pager -- true')->status, 0, '-Mup true');

# Test with --no-pager to avoid interactive mode
like(run('-Mup --no-pager -- echo hello')->stdout, qr/hello/, '-Mup echo hello');

# Test column layout by checking data distribution
# With -C2 --height=8, 1..10 should split into two columns (1-8 and 9-10)
subtest 'column layout' => sub {
    my $out = optex('-Mup', '--no-pager', '-C2', '--height=8', '--bs=none', '--',
                    'perl', '-e', 'print "$_\n" for 1..10')->run->stdout;
    like($out, qr/^.*\b1\b.*\b9\b.*$/m, '1 and 9 on same line (2 columns)');
    like($out, qr/^.*\b2\b.*\b10\b.*$/m, '2 and 10 on same line (2 columns)');
};

# Test grid option
is(run('-Mup -G2x2 --no-pager -- true')->status, 0, '-G2x2 option works');
is(run('-Mup -G3,2 --no-pager -- true')->status, 0, '-G3,2 option works');

# Test invalid grid format
isnt(run('-Mup -Gabc --no-pager -- true')->status, 0, 'invalid grid fails');

# Test pane and row options
is(run('-Mup -C2 --no-pager -- true')->status, 0, '-C2 option works');
is(run('-Mup -R2 --no-pager -- true')->status, 0, '-R2 option works');
is(run('-Mup -C2 -R2 --no-pager -- true')->status, 0, '-C2 -R2 options work');

# Test border-style option
is(run('-Mup --bs=round-box --no-pager -- true')->status, 0, '--bs option works');

# Test line-style option
is(run('-Mup --ls=truncate --no-pager -- true')->status, 0, '--ls=truncate works');
is(run('-Mup --ls=wrap --no-pager -- true')->status, 0, '--ls=wrap works');

done_testing;
