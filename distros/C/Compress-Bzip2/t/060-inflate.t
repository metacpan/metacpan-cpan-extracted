# -*- mode: perl -*-

use Test::More tests => 5;

## stream uncompress sample2 from the bzip2 1.0.2 distribution
## compare against bunzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

our ( $debugf, $BZIP );

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample2.bz2) );
( my $MODELFILE = $INFILE ) =~ s/\.bz2$/.ref/;
my $PREFIX = catfile( qw(t 060-tmp) );

my ( $in, $out, $d, $outbuf, $status, $counter, $bytes, $bytesout );
$debugf = $ENV{DEBUG} ? 1 : 0;
open( $in, "< $INFILE" ) or die "$INFILE: $!";
open( $out, "> $PREFIX-out.txt" ) or die "$PREFIX-out.txt: $!";

## verbosity 0-4, small 0,1, blockSize100k 1-9, workFactor 0-250, readUncompressed 0,1
( $d, $status ) = bzinflateInit( -verbosity => $debugf ? 4 : 0 );

ok( $d && $status == BZ_OK, "bzinflateInit was successful" );

$counter = 0;
$bytes = 0;
$bytesout = 0;
while ( my $ln = sysread( $in, $buf, 512 ) ) {
  # test buf as scalar or scalarref
  ( $outbuf, $status ) = $d->bzinflate( $counter % 2 ? \$buf : $buf );
  # the 2nd attempt to read from the 512 buf in bzfile_streambuf_read will cause a BZ_IO_ERROR
  if ( $status != BZ_IO_ERROR && $status != BZ_STREAM_END && $status != BZ_OK || !defined($outbuf) ) {
    diag "error: $outbuf $bzerrno\n";
    last;
  }

  if ( $outbuf ne '' ) {
    syswrite( $out, $outbuf );
    $bytesout += length($outbuf);
  }

  $bytes += $ln;
  $counter++;
}

( $outbuf, $status ) = $d->bzclose;
ok( $status == BZ_OK, "bzclose was successful" );

if ( defined($outbuf) && $outbuf ne '' ) {
  syswrite( $out, $outbuf );
  $bytesout += length($outbuf);
  
  $counter++;
}

ok( $bytes && $bytesout, "$counter blocks read, $bytes bytes in, $bytesout bytes out" );

close($in);
close($out);

#system( "$BZIP -d < $INFILE | od -x > $PREFIX-reference-txt.odx" );
#system( "od -x < $PREFIX-out.txt > $PREFIX-out-txt.odx" );
#system( "diff $PREFIX-out-txt.odx $PREFIX-reference-txt.odx > $PREFIX-diff.txt" );
#ok( ! -s "$PREFIX-diff.txt", "no differences with bunzip2" );

ok ( compare_binary_files( "$PREFIX-out.txt", $MODELFILE ), 'no differences with decompressing $INFILE' );
