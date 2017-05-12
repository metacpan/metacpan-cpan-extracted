# -*- mode: perl -*-

use Test::More tests => 5;
#use Test::More qw(no_plan);

## test bzflush
## stream compress sample2 from the bzip2 1.0.2 distribution
## verify bunzip2 can reconstruct the output

BEGIN {
  use_ok('Compress::Bzip2');
};

our ( $debugf, $BZIP );

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample2.ref) );
( my $MODELFILE = $INFILE ) =~ s/\.ref$/.bz2/;
my $PREFIX = catfile( qw(t 051-tmp) );

my ( $in, $out, $d, $outbuf, $counter, $bytes, $bytesout, $flushcount, $bytesflushedmark );

open( $in, "< $INFILE" ) or die "$INFILE: $!";
open( $out, "> $PREFIX-out.bz2" ) or die "$PREFIX-out.bz2: $!";

## verbosity 0-4, small 0,1, blockSize100k 1-9, workFactor 0-250, readUncompressed 0,1
$d = bzdeflateInit( -verbosity => $debugf ? 4 : 0 );

ok( $d, "bzdeflateInit was successful" );

$counter = 0;
$bytes = 0;
$bytesout = 0;
$bytesflushedmark = 0;
$flushcount = 0;
while ( my $ln = sysread( $in, $buf, 512 ) ) {
  $outbuf = $d->bzdeflate( $buf );
  if ( !defined($outbuf) ) {
    print STDERR "error: $outbuf $bzerrno\n";
    last;
  }

  if ( $bytes - $bytesflushedmark > 50_000 && $outbuf eq '' ) {
    $outbuf = $d->bzflush;
    $flushcount++ if $outbuf;
    $bytesflushedmark = $bytes;
  }

  if ( $outbuf ne '' ) {
    syswrite( $out, $outbuf );
    $bytesout += length($outbuf);
  }

  $bytes += $ln;
  $counter++;
}

$outbuf = $d->bzclose;
if ( defined($outbuf) && $outbuf ne '' ) {
  syswrite( $out, $outbuf );
  $bytesout += length($outbuf);
  
  $counter++;
}

ok( $bytes && $bytesout, "$counter blocks read, $bytes bytes in, $bytesout bytes out" );
ok( $flushcount, "successful flushes at 50,000 - $flushcount" );

close($in);
close($out);

system( "$BZIP -d < $PREFIX-out.bz2 > $PREFIX-reference-out-bunzip2.txt" );
#system( "od -x < $INFILE > $PREFIX-infile.odx" );
#system( "diff $PREFIX-infile.odx $PREFIX-reference-out-bunzip.odx > $PREFIX-diff.txt" );
#ok( ! -s "$PREFIX-diff.txt", "no differences with bzip2" );

ok ( compare_binary_files( $INFILE, "$PREFIX-reference-out-bunzip2.txt" ), "no differences with 50k stream compressing $INFILE" );
