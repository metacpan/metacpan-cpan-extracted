#! perl
use strict;
use 5.006002;
use Compress::Bzip2;
use File::Spec;
use Memory::Usage;
# Note that Test::LeakTrace does not find the XS leaks here. Always use Memory::Usage also.

use constant MAX   => 5; # MAX times all files in t => 125MB with 75, 15MB with 5, 43MB with 25
use constant MAX_5 => MAX >= 5 ? MAX / 5 : 1;
my $bigfile = File::Spec->catfile('t', '090-tmp-bigfile.bz2');

sub t_compress {
  warn "Creating $bigfile ...\n";
  my $buf;
  my $mu = Memory::Usage->new();
  $mu->record("Before bzopen");
  my $bz = Compress::Bzip2::bzopen($bigfile, "w");
  for (0 .. MAX) {
    $mu->record("Before bzwrite: $_") unless $_ % MAX_5;
    for my $infile (glob "t/*") {
      next if $infile eq $bigfile;
      open(my $fh, "<", $infile);
      while ( read( $fh, $buf, 65335 ) ) {
        $bz->bzwrite( $buf );
      }
      close $fh;
    }
    $mu->record("After bzwrite: $_") unless $_ % MAX_5;
  }
  $bz->bzclose;
  $mu->record("After bzclose");
  $mu->dump();
  system("bunzip2", "-tv", $bigfile);
  warn("  size: ", -s $bigfile, "\n");
}

sub t_uncompress {
  warn "Uncompressing $bigfile 5x ...\n";
  my $buf;
  my $mu = Memory::Usage->new();
  for ( 1 .. 5 ) {
    my $bz = Compress::Bzip2::bzinflateInit( -verbosity => 0 );
    $mu->record("Before bunzip: $_");
    open( my $fh, '<', $bigfile );
    while ( read( $fh, $buf, 65335 ) ) {
        my ( $output, $status ) = $bz->bzinflate( $buf );
    }
    close($fh);
    $bz->bzclose();
    $mu->record("After bunzip: $_");
  }
  $mu->dump();
}

t_compress() unless -f $bigfile;
t_uncompress();

unlink $bigfile;
