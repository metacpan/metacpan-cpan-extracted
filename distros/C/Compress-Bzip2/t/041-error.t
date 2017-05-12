# -*- mode: perl -*-

use Test::More tests => 9;
use Fcntl;

BEGIN {
  use_ok('Compress::Bzip2');
};

our ( $debugf, $BZIP );

do './t/lib.pl';

my $INFILE = catfile( qw(bzlib-src sample0.ref) );
( my $MODELFILE = $INFILE ) =~ s/\.ref$/.bz2/;
my $PREFIX = catfile( qw(t 041-tmp) );

## verbosity 0-4, small 0,1, blockSize100k 1-9, workFactor 0-250, readUncompressed 0,1
my ( $d, $err, $in, $out, $buf, $res );

$d = Compress::Bzip2->new( -workFactor => 1000 );
ok( $d, "object created in spite of error" );
$err = $d->bzerror;
ok( $err, "error is set '$err' vs '$bzerrno'" );

$d->bzclearerr;

$err = $d->bzerror;
ok( !$err, "after bzclearerr, error is not set '$err' vs '$bzerrno'" );
my $TMPFILE = "$PREFIX-protected.bz2";
unlink( $TMPFILE ) if -f $TMPFILE;

SKIP: {
  skip "bzclose handle not with 5.6", 2 if $] < 5.008;
  sysopen( $out, $TMPFILE, O_WRONLY|O_CREAT ) or die "failed $TMPFILE $!";
  ok( $d->bzopen( $out, "w" ), "bzopen with file handle instead of file" );

  open( $in, "<", $INFILE );
  while ( my $ln = sysread( $in, $buf, 512 ) ) {
    $res = $d->bzwrite( $buf, $ln );
    if ( $res < 0 ) {
      print STDERR "error: $res $bzerrno\n";
      last;
    }
  }

  $res = $d->bzclose;
  ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );
}

close($in);

if ($] < 5.008) {
  require File::Copy;
  File::Copy::syscopy($MODELFILE, $TMPFILE);
  chmod( 0644, $TMPFILE ) or die;
}
ok ( compare_binary_files( $MODELFILE, $TMPFILE ), "no differences with $MODELFILE reference" );

chmod( 0000, $TMPFILE ) or die;

SKIP: {
  skip "0000 but writable ($>/$^O)", 2 if -w $TMPFILE;

  $d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0, -blockSize100k => 1 );
  $res = $d->bzopen( $TMPFILE, "w" );

  ok( !$res, "open failed" );

  $res = $d->bzerror;
  ok( $res, "error set, is '$res' '$bzerrno'" );
}
