# -*- mode: perl -*-

use Test::More tests => 12;
#use Test::More qw(no_plan);

## using the large bzip2 1.0.2 test file from test 022
## run the test using total_in, total_out and bzflush
## compare against bzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

our ( $debugf, $BZIP );

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample2.ref) );
( my $MODELFILE = $INFILE ) =~ s/\.ref$/.bz2/;
my $PREFIX = catfile( qw(t 026-tmp) );

my $in;
open( $in, "< $INFILE" );

my $d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0, -blockSize100k => 1 );
$d->bzopen( "$PREFIX-sample.bz2", "w" );

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
ok( $counter, "$counter data was written, $bytes bytes" );

my $res = $d->bzflush;
ok( !$res, "flush test of write file, res=$res" );

my $total_in = $d->total_in;
my $total_out_b4 = $d->total_out;

$res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

my $total_out = $d->total_out;

close($in);

ok( $total_in, "something was read in, $total_in bytes" );
ok( $total_out_b4, "flush wrote out something, $total_out_b4 bytes" );
ok( $total_out, "something was written out, $total_out bytes" );

ok( $total_out_b4 < $total_out, "file trailer written by bzclose" );

ok( $total_in == -s $INFILE, "total_in should be ".(-s $INFILE).", is $total_in" );
ok( $total_out == -s "$PREFIX-sample.bz2", "total_out should be ".(-s "$PREFIX-sample.bz2").", is $total_out" );

#system( "bzip2 -1 < $INFILE | od -x > $PREFIX-reference-bz2.odx" );
#system( "od -x < $PREFIX-sample.bz2 | diff - $PREFIX-reference-bz2.odx > $PREFIX-diff.txt" );
#ok( ! -s "$PREFIX-diff.txt", "no differences with bzip2" );

system( "$BZIP -1 < $INFILE > $PREFIX-reference.bz2" );
ok ( compare_binary_files( "$PREFIX-sample.bz2", "$PREFIX-reference.bz2" ), 'no differences with reference' );
