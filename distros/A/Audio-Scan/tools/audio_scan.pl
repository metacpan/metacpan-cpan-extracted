#!/usr/bin/env perl

use lib qw(blib/lib blib/arch);
use strict;

use Audio::Scan;
use Data::Dump qw(dump);

my $file;
my $arg = shift;

if ( $arg eq '--with-artwork' ) {
    $file = shift;
}
else {
    $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
    $file = $arg;
}

die "Usage: $0 [--with-artwork] FILE\n" unless $file;

my $s = Audio::Scan->scan($file);

warn dump($s) . "\n";
