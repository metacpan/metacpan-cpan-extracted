# -*- mode: perl -*-

use Test::More tests => 9;

## compress sample1 from the bzip2 1.0.2 distribution

BEGIN {
  use_ok('Compress::Bzip2');
};

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample1.ref) );
( my $MODELFILE = $INFILE ) =~ s/\.ref$/.bz2/;
my $PREFIX = catfile( qw(t 011-tmp) );

my $in;
open( $in, $INFILE );

my $d;
ok( eval '$d = bzopen( "$PREFIX-sample.bz2", "w" ); 1;', "bzopen prototype ok" );
ok( $d, "bzopen $PREFIX-sample.bz2 successful" );
ok( eval '$d->bzsetparams( -blockSize100k => 1 ); 1;', "bzsetparams prototype ok" );

my $counter = 0;
my $bytes = 0;
my $buf;
my ( $evalres1, $evalres2 );
while ( my $ln = read( $in, $buf, 512 ) ) {
  my $out1 = -1;
  my $out2 = -1;
  $evalres1 = eval '$out1 = $d->bzwrite( $buf, $ln ); 1;';
  last if !$evalres1;

  $evalres2 = eval '$out2 = $d->bzwrite( $buf ); 1;';
  last if !$evalres2;

  if ( $out1 < 0 || $out2 < 0 || $out1 != $out2 ) {
    print STDERR "error: $out1 $out2 $Compress::Bzip2::bzerrno\n";
    last;
  }
  $bytes += $ln;
  $counter++;
}
ok( defined($evalres1), 'bzwrite prototype $$$ ok'.($@ ? " - $@" : '') );
ok( defined($evalres2), 'bzwrite prototype $$ ok'.($@ ? " - $@" : '') );
ok( $counter, "$counter blocks were read, $bytes bytes" );

my $res;
ok( eval '$res = $d->bzclose; 1;', 'bzclose prototype ok' );
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($in);

