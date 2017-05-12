#!/usr/bin/env perl

use lib qw(blib/lib blib/arch);
use strict;

use Audio::Scan;
use Data::Dump qw(dump);

$ENV{AUDIO_SCAN_NO_ARTWORK} = 1;

my $file = shift || die "Usage: $0 [file]\n";

my $s = Audio::Scan->scan($file);

warn dump($s) . "\n";
