#!/usr/bin/perl
# findshapes.pl.

use strict;
use Getopt::Std ();
use Acme::EyeDrops qw(get_eye_shapes
                      find_eye_shapes
                      get_eye_string
                      get_eye_properties
                      get_eye_keywords);

sub usage
{
   print STDERR <<'EOM';
usage: findshapes [-kvH] [keywords]
Options:
  -k              List shapes by keyword
  -H              List keyword histogram
  -v              Verbose (display shape in addition to shape properties)
Notes:
  You cannot specify keywords with -k and -H options.
  The -v option does not apply to -k and -H options.
Examples:
  findshapes face person perlhacker
     Find all shapes containing keywords face AND person AND perlhacker.
  findshapes face 'person OR perlhacker'
     Find all shapes containing keywords face AND (person OR perlhacker).
  findshapes -v face 'person OR perlhacker'
     Find all shapes containing keywords face AND (person OR perlhacker).
     This time also display the shape contents.
  findshapes
     List all available shapes and their properties.
  findshapes -v
     List all available shapes, their properties and contents.
  findshapes -k
     List all shapes by keyword.
  findshapes -H
     List keyword histogram.
EOM
   exit 1;
}

my %option = ();
Getopt::Std::getopts("hkHv", \%option) or usage();
usage() if $option{h};

if ($option{k} || $option{H}) {
   usage() if @ARGV;
   my $h = get_eye_keywords();
   if ($option{k}) {
      for my $k (sort keys %{$h}) { print "$k: @{$h->{$k}}\n" }
   }
   if ($option{H}) {
      for my $k (sort keys %{$h}) { print "$k: ", scalar(@{$h->{$k}}), "\n" }
   }
   exit(0);
}

my @shapes;
if (@ARGV) {
   @shapes = find_eye_shapes(@ARGV);
} else {
   @shapes = get_eye_shapes();
}

for my $s (@shapes) {
   print "--$s--\n";
   my $p = get_eye_properties($s) or next;
   for my $k (sort keys %{$p}) {
      printf "  %-13.13s: %s\n", $k, $p->{$k};
   }
   if ($option{v}) {
      print get_eye_string($s);
   }
}
