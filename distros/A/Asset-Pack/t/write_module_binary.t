use strict;
use warnings;

use Test::More tests => 1 * 2;

use 5.006;
use Path::Tiny;
use Test::TempDir::Tiny qw(tempdir);
use Asset::Pack qw(write_module);
use Test::Differences qw( eq_or_diff );

my $tempdir = tempdir;
unshift @INC, $tempdir;

my $binfile = path( $tempdir, 'binary_ranges.bin' );
{
  my $fh = $binfile->openw_raw;
  print {$fh} "Double\n";

  for my $first ( 0 .. 255 ) {
    for my $second ( 0 .. 255 ) {
      print {$fh} chr for $first, $second;
      print {$fh} "\n" if ( ( $first * 255 ) + $second ) % 10 == 0;
    }
  }
  close $fh;
}

my %paths = ( "$binfile" => "Test::BinFile", );
foreach my $p ( keys %paths ) {
  my $content = path($p)->slurp_raw;
  my $l       = length($content);
  write_module( $p, $paths{$p}, $tempdir );
  use_ok( $paths{$p} );
  {
    no strict 'refs';
    eq_or_diff( ${"$paths{$p}::content"}, $content, "Loaded and decoded $l bytes from copy of $p" );
  }
}
