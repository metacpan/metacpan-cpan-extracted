# -*- mode: perl -*-

use Test::More tests => 5;
#use Test::More qw(no_plan);

## compress a simple text file - the lyrics to end of the world REM
## compare against bzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample0.ref) );
( my $MODELFILE = $INFILE ) =~ s/\.ref$/.bz2/;
my $PREFIX = catfile( qw(t 020-tmp) );

my $in;
open( $in, $INFILE );

my $d = bzopen( "$PREFIX-sample.bz2", "w" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;
while ( my $ln = read( $in, $buf, 512 ) ) {
  my $out = $d->bzwrite( $buf, $ln );
  if ( $out < 0 ) {
    print STDERR "error: $out $Compress::Bzip2::bzerrno\n";
    last;
  }
  $bytes += $ln;
  $counter++;
}
ok( $counter, "$counter blocks were read, $bytes bytes" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($in);

ok ( compare_binary_files( "$PREFIX-sample.bz2", $MODELFILE ), 'no differences with reference' );
#system( "bzip2 < $INFILE | od -x > $PREFIX-reference-bz2.odx" );
#system( "od -x < $PREFIX-sample.bz2 | diff - $PREFIX-reference-bz2.odx > $PREFIX-diff.txt" );

#ok( ! -s "$PREFIX-diff.txt", "no differences with bzip2" );
