#!perl

use Test::Most;
plan tests => 2;
bail_on_fail if 0;
use Env::Path 'PATH';

ok(scalar PATH->Whence($_), "$_ in PATH") for qw(blastn makeblastdb);

