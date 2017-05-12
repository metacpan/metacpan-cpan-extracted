#!perl -w

# Just make sure we can actually read and write actual files, and that
# our binary works.

use strict;
use warnings;
use Test::More;
BEGIN {
  eval "use Test::TempDir; 1" or do {
    plan skip_all => "Please install Test::TempDir";
    exit 0;
  };
  plan tests => 2;
}

use File::Spec;
use FindBin qw($Bin);

our $temp_root = temp_root();
our $csv_bin   = File::Spec->catfile($Bin, '..', 'bin', 'csv');
our $infile    = File::Spec->catfile($Bin, "input1.csv");

test_to('output1.csv');
test_to('output1.tsv');

sub test_to {
  my($dst) = @_;
  my $expected_outfile = File::Spec->catfile($Bin, $dst);
  my $outfile = File::Spec->catfile($temp_root, $dst);

  my @args = ("csv", libs(), $csv_bin,
      '--input' => $infile, '--output' => $outfile, 2, 1);
  diag("system {$^X} @args");
  system {$^X} @args and die "system: $!";

  diag("temporary output at $outfile");
  is(slurp($outfile), slurp($expected_outfile),
      "$dst - actual commandline invocation produces correct results");
}

sub libs { map { ('-I' => $_) } @INC }
sub slurp { local $/; local @ARGV = pop; <> }
