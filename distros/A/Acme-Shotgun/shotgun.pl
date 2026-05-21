#!/usr/bin/env perl
# shotgun.pl - Shoots holes in files (CLI wrapper for Acme::Shotgun)
# Written by John R., Nov. 2023 — refactored to use Acme::Shotgun

use strict;
use warnings;

use Getopt::Long;

use lib "./lib";
use Acme::Shotgun;

sub usage {
    my $err_msg = shift;
    print "$err_msg\n" if $err_msg;
    print <<~EOF;
      Name:
          shotgun.pl - Shoots holes in files

      Usage:
          shotgun.pl -target <file> [options]

      Options (required):
          -target                   File you want to shoot holes in

      Options (optional):
          -help                     Print this help menu
          -type [double|pump]       Shotgun type
          -load [bird|buck|slug]    Type of ammunition
          -shots [int]              Number of shots to fire
          -check                    Print mag state before firing
          -quiet                    Suppress output
          -debug                    Debug mode, takes no action
          -verbose                  Verbose mode, more verbose output

      Defaults:
          -type double
          -load bird

    EOF
    exit;
}

my %O = (
    debug   => 0,
    verbose => 1,
    type    => 'double',
    load    => 'bird',
);

GetOptions(\%O,
    'help',
    'debug',
    'verbose!',
    'target=s',
    'type=s',
    'load=s',
    'shots=i',
    'check',
    'quiet',
) or usage();

usage()                             if $O{help};
usage("Missing required argument!") unless $O{target};

my $gun = Acme::Shotgun->new(
    type    => $O{type},
    load    => $O{load},
    shots   => $O{shots},
    quiet   => $O{quiet}   // 0,
    debug   => $O{debug}   // 0,
    verbose => $O{verbose} // 1,
);

$gun->check() if $O{check};
$gun->fire(target => $O{target});
