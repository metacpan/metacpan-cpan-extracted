#!/usr/bin/env perl

use Test::Most;
plan tests => 11;
bail_on_fail if 0;
use Env::Path 0.18 'PATH';

ok(scalar PATH->Whence($_), "$_ in PATH") for qw(awk less grep egrep sed find makeblastdb blastp prodigal parallel hmmscan);

