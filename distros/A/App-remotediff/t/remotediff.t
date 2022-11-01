#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

if (system("which rsync") != 0)
{
    plan skip_all => "rsync required for this test";
}
else
{
    plan tests => 1;

is(scalar(`"$^X" -Ilib script/remotediff -q t/data/file1 t/data/file2`), <<'EOF'
Files t/data/file1 and t/data/file2 differ
EOF
, "remotediff - local diff quiet no tty");

}
