# -*- mode: perl -*-

use Test::More tests => 4;
#use Test::More qw(no_plan);

## compress sample2 from the bzip2 1.0.2 distribution
## compare against bzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

our ( $debugf, $BZIP );

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample2.ref) );
( my $MODELFILE = $INFILE ) =~ s/\.ref$/.bz2/;
my $PREFIX = catfile( qw(t 050-tmp) );

my ( $in, $out, $d, $outbuf, $counter, $bytes, $bytesout );

open( $in, "< $INFILE" ) or die "$INFILE: $!";
open( $out, "> $PREFIX-out.bz2" ) or die "$PREFIX-out.bz2: $!";

## verbosity 0-4, small 0,1, blockSize100k 1-9, workFactor 0-250, readUncompressed 0,1
$d = bzdeflateInit( -verbosity => $debugf ? 4 : 0, -blockSize100k => 2 );

ok( $d, "bzdeflateInit was successful" );

$counter = 0;
$bytes = 0;
$bytesout = 0;
while ( my $ln = sysread( $in, $buf, 512 ) ) {
  $outbuf = $d->bzdeflate( $buf );
  if ( !defined($outbuf) ) {
    print STDERR "error: $outbuf $bzerrno\n";
    last;
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

close($in);
close($out);

#system( "$BZIP -1 < $INFILE | od -x > $PREFIX-reference-bz2.odx" );
#system( "od -x < $PREFIX-out.bz2 > $PREFIX-out-bz2.odx" );
#system( "diff $PREFIX-out-bz2.odx $PREFIX-reference-bz2.odx > $PREFIX-diff.txt" );
#ok( ! -s "$PREFIX-diff.txt", "no differences with bzip2" );

ok ( compare_binary_files( "$PREFIX-out.bz2", $MODELFILE ), "no differences with stream compressing $INFILE" );
