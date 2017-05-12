#! /usr/bin/perl
#---------------------------------------------------------------------
# compact.pl
# Copyright 2006 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Simple Run-Length-Encoded file compression
#
# Usage: compact.pl INFILE OUTFILE
#---------------------------------------------------------------------

use strict;
use bytes;
use IO::All;

#---------------------------------------------------------------------
open OUT, '>', $ARGV[1] or die $!;
binmode OUT;

#---------------------------------------------------------------------
sub printChunk
{
  my $chunk = $_[0];

  while (length $chunk > 0xFFFF) {
    print OUT "\xFF\xFF" . substr($chunk, 0, 0xFFFF, '') . "\0\0";
  } # end while too much data for a single chunk

  print OUT pack('n', length($chunk)) . $chunk;
} # end printChunk

#---------------------------------------------------------------------
sub printNulls
{
  my $nulls = $_[0];

  while ($nulls > 0xFFFF) {
    print OUT "\xFF\xFF\0\0";
    $nulls -= 0xFFFF;
  } # end while too many nulls for a single count

  print OUT pack('n', $nulls);
} # end printNulls

#=====================================================================
# A compressed file just alternates between a count of null bytes and
# a data chunk (count + raw data).  All counts are unsigned network
# shorts.

my $data = io($ARGV[0])->binmode->scalar;

my $nulls = 0;

$nulls = $+[0] - $-[0] if $data =~ s/^\0+//;

printNulls($nulls);

while ($data =~ s/^([^\0].*?)\0{4,}(?=[^\0]|$)//s) {
  $nulls = $+[0] - $+[1];
  printChunk($1);

  printNulls($nulls);
}

printChunk($data) if length $data;

close OUT;
