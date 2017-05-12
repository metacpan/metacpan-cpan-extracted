use strict;
use warnings;
use Test::More;

my $got = `$^X bin/load_watcher --version`;
like $got, qr{^load_watcher: [0-9._]+$};

done_testing;
