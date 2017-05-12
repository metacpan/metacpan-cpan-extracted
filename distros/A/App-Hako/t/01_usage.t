use strict;
use Test::More 0.98;

# We want to run the script, which we are probably still building.
$ENV{PATH} = "blib/script:$ENV{PATH}";

my $out;

$out = qx{hako 2>&1};
is $?>>8, 64, "usage";
like $out, qr/^usage: /;

$out = qx{hako --help 2>&1};
is $?>>8, 0, "help";
like $out, qr/^usage: /;

done_testing;

