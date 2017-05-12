#!/usr/bin/perl
use strict;
use warnings;

use FindBin;  use lib "$FindBin::Bin/../lib";
use Moo::Role qw/apply_roles_to_object/;
use Data::BitStream;

my $stream = Data::BitStream->new();
die unless defined $stream;
Moo::Role->apply_roles_to_object($stream, qw/Data::BitStream::Code::Escape/);

my $p = 0;
while (<>) {
  chomp;
  # Allows setting the parameter via:  p=....
  if (/^p\s*=?\s*\[(.*)\]/) { $p = [split(/-|,|\s+/,$1)]; print "Set p to '[",join(",",@$p),"]'\n"; next; }
  if (/^p\s*=?\s*(.*)/)     { $p = $1; print "Set p to '$p'\n"; next; }
  # Ignore non-digit input
  next unless /^\d+$/;
  # Save the value
  my $v = $_;

  $stream->erase_for_write;
  $stream->put_baer($p, $v);
  #$stream->put_escape($p, $v);

  my $s = $stream->to_string;
  print "        $s\n";

  $stream->rewind_for_read;
  my $d = $stream->get_baer($p);
  #my $d = $stream->get_escape($p);
  if ($d != $v) {
    print "DECODED:  $d instead of $v\n";
  }
}
