#!/usr/bin/perl -w
################################################################################
#
# PROGRAM: check_alloc.pl
#
################################################################################
#
# DESCRIPTION: Check for memory leaks and print memory usage statistics
#
################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use strict;

my(%alloc, %free);
my %info = (
  allocs     => 0,
  frees      => 0,
  max_blocks => 0,
  max_total  => 0,
);
my $count = 0;
my $total = 0;

LOOP: while( <> ) {
  next unless /^(.*?):(A|F|V|B)=(?:(\d+)\@)?([0-9a-fA-F]{8,})$/;
  if( $2 eq 'A' ) {
    if( exists $alloc{$4} ) {
      print "Previously allocated in $alloc{$4}[0]: 0x$4 in $1\n";
      next;
    }
    my $addr = hex $4;
    $alloc{$4} = [$1,$3,$addr,$addr+$3-1];
    $count++;
    $total += $3;
    $info{allocs}++;
    $info{min_size} = $info{max_size} = $3 unless exists $info{min_size};
    $info{min_size} = $3 if $3 < $info{min_size};
    $info{max_size} = $3 if $3 > $info{max_size};
  }
  elsif( $2 eq 'F' ) {
    unless( exists $alloc{$4} ) {
      if( $4 eq '00000000' ) {
        print "Freeing NULL pointer in $1\n" if $4 eq '00000000';
      }
      elsif( exists $free{$4} ) {
        print "Freeing block more than once: 0x$4 in $1\n";
      }
      else {
        print "Freeing block not previously allocated: 0x$4 in $1\n";
      }
      next;
    }
    $count--;
    $total -= $alloc{$4}[1];
    $info{frees}++;
    $free{$4} = delete $alloc{$4};
  }
  elsif( $2 eq 'V' ) {
    unless( exists $alloc{$4} ) {
      if( $4 eq '00000000' ) {
        print "Trying to validate NULL pointer in $1\n"
      }
      else {
        print "Valid pointer assertion (0x$4) failed in $1\n";
        if( exists $free{$4} ) {
          print "  - pointer references a block that has been freed\n";
        }
        else {
          print "  - pointer references memory not previously allocated\n";
        }
      }
    }
    next; # nothing needs to be updated
  }
  else { # $2 eq 'B'
    if( $4 eq '00000000' ) {
      print "Trying to validate block starting at NULL\n";
      next;
    }

    my($min, $max);
    my(@overlaps, @old_blocks, @old_overlaps);

    $min = hex $4;
    $max = $min + $3 - 1;
    # print "[$4,$3] [min] => $min, [max] => $max\n";

    # check allocated blocks
    for my $key ( keys %alloc ) {
      my $info = $alloc{$key};
      # print "alloc: [2] => $info->[2], [3] => $info->[3]\n";
      my $min_in = $info->[2] <= $min && $min <= $info->[3];
      my $max_in = $info->[2] <= $max && $max <= $info->[3];
      my $over   = $min < $info->[2] && $max > $info->[3];

      next unless $min_in || $max_in || $over;
      next LOOP if $min_in && $max_in;

      push @overlaps, $key;
    }

    # check freed blocks
    for my $key ( keys %free ) {
      my $info = $free{$key};
      # print "free: [2] => $info->[2], [3] => $info->[3]\n";
      my $min_in = $info->[2] <= $min && $min <= $info->[3];
      my $max_in = $info->[2] <= $max && $max <= $info->[3];
      my $over   = $min < $info->[2] && $max > $info->[3];

      next unless $min_in || $max_in || $over;
      if( $min_in && $max_in ) {
        push @old_blocks, $key;
        last;
      }

      push @old_overlaps, $key;
    }

    print "Block assertion (0x$4, size $3) failed in $1\n";

    if( @overlaps || @old_blocks || @old_overlaps ) {
      print "  - overlaps with allocated block at 0x$_, size $alloc{$_}[1]\n"
        for @overlaps;
      print "  - references memory in old block at 0x$_, size $free{$_}[1]\n"
        for @old_blocks;
      print "  - overlaps with old block at 0x$_, size $free{$_}[1]\n"
        for @old_overlaps;
    }
    else {
      print "  - references memory not previously allocated\n";
    }

    next; # nothing needs to be updated
  }
  $info{max_blocks} = $count if $count > $info{max_blocks};
  $info{max_total}  = $total if $total > $info{max_total};
}

foreach( sort keys %alloc ) {
  print "Not freed: block at 0x$_, size $alloc{$_}[1], allocated in $alloc{$_}[0]\n";
}

print <<ENDSTATS;

Summary Statistics:

  Total allocs       : $info{allocs}
  Total frees        : $info{frees}
  Max. memory blocks : $info{max_blocks}
  Max. memory usage  : $info{max_total} bytes

  Smallest block     : $info{min_size} bytes
  Largest block      : $info{max_size} bytes

  Memory leakage     : $total bytes

ENDSTATS
