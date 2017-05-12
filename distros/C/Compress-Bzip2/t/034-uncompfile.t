# -*- mode: perl -*-

use Test::More tests => 5;
#use Test::More qw(no_plan);

## uncompress sample3 compressed file from the bzip2 1.0.2 distribution
## compare against bunzip2 command with od -x and diff

## test uncompressing a large file
## - make up a large file by essentially repeating one of the other sample files

BEGIN {
  use_ok('Compress::Bzip2');
};

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample1.ref) );
#( my $MODELFILE = $INFILE ) =~ s/\.bz2$/.ref/;
my $PREFIX = catfile( qw(t 034-tmp) );

my $in;
my $out;
my $dup;
open( $in, $INFILE ) or die;

print STDERR "Running $BZIP -1 > $PREFIX-reference.bz2\n" if $debugf;

my $filecount = 11;

open( $out, "| $BZIP -1 > $PREFIX-reference.bz2" ) or die;
open( $dup, "> $PREFIX-reference.txt" ) or die;

my $MODELFILE = "$PREFIX-reference.txt";

for (my $i=0; $i<$filecount; $i++) {
  while ( my $ln = sysread( $in, $buf, 512 ) ) {
    syswrite($out, $buf, $ln);
    syswrite($dup, $buf, $ln);
  }
  sysseek($in,0,0);
}
close($in);
close($out);
close($dup);

undef $out;
open( $out, "> $PREFIX-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0 );
$d->bzopen( "$PREFIX-reference.bz2", "r" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;
my $written = 0;
while ( my $read = $d->bzread( $buf, 512 ) ) {
  if ( $read < 0 ) {
    print STDERR "error: $bytes $Compress::Bzip2::bzerrno\n";
    last;
  }

  $written = syswrite( $out, $buf, $read );

  $bytes += $read;
  $counter++;
}
ok( $counter, "$counter blocks were read, $bytes bytes" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($out);

ok ( compare_binary_files( "$PREFIX-sample.txt", $MODELFILE ), "no differences with decompressing $INFILE times 11" );
