# -*- mode: perl -*-

use Test::More tests => 7;
#use Test::More qw(no_plan);

## uncompress sample2 compressed file from the bzip2 1.0.2 distribution
## compare against bunzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample2.bz2) );
( my $MODELFILE = $INFILE ) =~ s/\.bz2$/.ref/;
my $PREFIX = catfile( qw(t 032-tmp) );


my $out;
open( $out, "> $PREFIX-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => 0 );
$d->bzopen( $INFILE, "r" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;

ok( !$d->bzeof, "not at EOF" );

my $read;
while ( $read = $d->bzread( $buf, 512 ) ) {
  if ( $read < 0 ) {
    print STDERR "error: $bytes $Compress::Bzip2::bzerrno\n";
    last;
  }

  $bytes += syswrite( $out, $buf, $read );
  $counter++;
}

ok( $d->bzeof, "at EOF" );

ok( $counter, "$counter data was written, $bytes bytes" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($out);

#system( "bunzip2 < $INFILE > $PREFIX-reference.txt" );
#system( "diff $PREFIX-sample.txt $PREFIX-reference.txt > $PREFIX-diff.txt" );
#ok( ! -s "$PREFIX-diff.txt", "no differences with bunzip2" );

ok ( compare_binary_files( "$PREFIX-sample.txt", $MODELFILE ), 'no differences with decompressing $INFILE' );
