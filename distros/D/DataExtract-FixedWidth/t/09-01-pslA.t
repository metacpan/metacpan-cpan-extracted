#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 1;
use File::Spec;
use DataExtract::FixedWidth;

my $file = File::Spec->catfile( 't', 'data', 'ps-lA.txt' );
open ( my $fh, $file ) || die "Can not open $file";

my @lines = <$fh>;

my $fw = DataExtract::FixedWidth->new({heuristic => \@lines});

my @rows = map $fw->parse_hash($_), @lines;

my $stored_arr = [
 undef,
 {
   'S' => 'S',
   'F' => '4',
   'PID' => '1',
   'TIME' => '00:00:02',
   'NI' => '0',
   'PPID' => '0',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'init',
   'ADDR SZ' => '-   711',
   'C' => '0',
   'PRI' => '80'
 },
 {
   'S' => 'S',
   'F' => '1',
   'PID' => '2',
   'TIME' => '00:00:00',
   'NI' => '-5',
   'PPID' => '0',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'kthreadd',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '75'
 },
 {
   'S' => 'S',
   'F' => '1',
   'PID' => '3',
   'TIME' => '00:00:00',
   'NI' => '-',
   'PPID' => '2',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'migration/0',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '-40'
 },
 {
   'S' => 'S',
   'F' => '1',
   'PID' => '4',
   'TIME' => '00:00:16',
   'NI' => '-5',
   'PPID' => '2',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'ksoftirqd/0',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '75'
 },
 {
   'S' => 'S',
   'F' => '5',
   'PID' => '5',
   'TIME' => '00:00:00',
   'NI' => '-',
   'PPID' => '2',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'watchdog/0',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '-40'
 },
 {
   'S' => 'S',
   'F' => '1',
   'PID' => '6',
   'TIME' => '00:00:00',
   'NI' => '-',
   'PPID' => '2',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'migration/1',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '-40'
 },
 {
   'S' => 'S',
   'F' => '1',
   'PID' => '7',
   'TIME' => '00:00:00',
   'NI' => '-5',
   'PPID' => '2',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'ksoftirqd/1',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '75'
 },
 {
   'S' => 'S',
   'F' => '5',
   'PID' => '8',
   'TIME' => '00:00:00',
   'NI' => '-',
   'PPID' => '2',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'watchdog/1',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '-40'
 },
 {
   'S' => 'S',
   'F' => '1',
   'PID' => '9',
   'TIME' => '00:00:00',
   'NI' => '-5',
   'PPID' => '2',
   'UID' => '0',
   'WCHAN' => '-',
   'TTY' => '?',
   'CMD' => 'events/0',
   'ADDR SZ' => '-     0',
   'C' => '0',
   'PRI' => '75'
 }
];

is_deeply( $stored_arr, \@rows, 'deep store of ps -lA' )
