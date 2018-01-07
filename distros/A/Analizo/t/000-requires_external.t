#!/usr/bin/env perl

use Test::Most;
plan tests => 4;
bail_on_fail if 1;
use Env::Path 0.18 'PATH';

ok(scalar PATH->Whence($_), "$_ in PATH") for qw(doxyparse sloccount sqlite3 man);

