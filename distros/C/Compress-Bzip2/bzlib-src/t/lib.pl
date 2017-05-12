use File::Copy;
use Cwd;
use Config;

BEGIN {
  eval { require File::Spec::Functions ; File::Spec::Functions->import( qw(catfile rel2abs) ) } ;
  *catfile = sub { return join( '/', @_ ) } if $@;
}

require VMS::Filespec if $^O eq 'VMS';

sub dump_block {
  my %block;
  ( $block{1}, $block{2} ) = @_;

  for ( my $i=0; $i<length($block{1}); $i+=16 ) {
    my %xbuf;

    foreach my $j ( 1, 2 ) {
      for ( my $k=0; $k<16 && $i+$k<length($block{$j}); $k++ ) {
	$xbuf{$j} .= ' ' if $xbuf{$j} && $k % 2 == 0;
	$xbuf{$j} .= unpack( "H2", substr($block{$j},$i+$k,1) );
      }

      printf STDERR "%03d %s\n", $i, $xbuf{$j};
    }

    print STDERR "\n";
  }
}

sub compare_binary_files {
  my ( $file1, $file2 ) = @_;
  my ( %fh, %buf, %ln, %counter );

  if ( -s $file1 != -s $file2 ) {
    print STDERR "files not the same size", " $file1 is ".(-s $file1), ", $file2 is ".(-s $file2),"\n";
    return 0;
  }

  open( $fh{1}, $file1 );
  open( $fh{2}, $file2 );

  my $same = 1;
  my $notdone;
  $counter{blocks}++;
  while ( !$notdone ) {
    $ln{1} = sysread( $fh{1}, $buf{1}, 512 );
    $ln{2} = sysread( $fh{2}, $buf{2}, 512 );
    if ( $ln{1} != $ln{2} ) {
      print STDERR "blocks not the same size\n";
      return 0;
    }
    if ($buf{1} ne $buf{2}) {
      print STDERR "block $counter{blocks} not the same\n";
      dump_block($buf{1}, $buf{2});
      return 0;
    }
    return 1 if $ln{1} == 0;
    $counter{blocks}++;
  }

  close( $fh{1} );
  close( $fh{2} );

  return 0;
}

sub display_file {
  my ( $file ) = @_;
  my $in;
  if ( !open( $in, $file ) ) {
    warn "Error: unable to open $file: $!\n";
  }
  else {
    while (<$in>) {
      print STDERR $_;
    }
    close($in);
  }
}
our $BZLIB_BIN ;
our $BZLIB_LIB ;
our $BZLIB_INCLUDE ;
our $BUILD_BZLIB ;

sub ParseCONFIG {
  my $CONFIG = shift || 'config.in' ;

  my ($k, $v) ;
  my @badkey = () ;
  my %Info = () ;
  my @Options = qw( BZLIB_INCLUDE BZLIB_LIB BUILD_BZLIB BZLIB_BIN ) ;
  my %ValidOption = map {$_, 1} @Options ;
  my %Parsed = %ValidOption ;
  my $debugf = 0;

  print STDERR "Parsing $CONFIG...\n" if $debugf;

  if (!open(F, "<$CONFIG")) {
    warn "warning: failed to open $CONFIG: $!\n";
  }
  else {
    while (<F>) {
      chomp;
      s/#.*$//;
      next if !/\S/;

      ($k, $v) = split(/\s*=\s*/, $_, 2) ;
      $k = uc $k ;

      if ($ValidOption{$k}) {
	delete $Parsed{$k} ;
	$Info{$k} = $v ;
      }
      else {
	push(@badkey, $k) ;
      }
    }
    close F ;
  }

  print STDERR "Unknown keys in $CONFIG ignored [@badkey]\n" if $debugf && scalar(@badkey) ;

  $BZLIB_INCLUDE = $ENV{'BZLIB_INCLUDE'} || $Info{'BZLIB_INCLUDE'} ;
  $BZLIB_LIB = $ENV{'BZLIB_LIB'} || $Info{'BZLIB_LIB'} ;
  $BZLIB_BIN = $ENV{'BZLIB_BIN'} || $Info{'BZLIB_BIN'} ;

  if ($^O eq 'VMS') {
    $BZLIB_INCLUDE = VMS::Filespec::vmspath($BZLIB_INCLUDE);
    $BZLIB_LIB = VMS::Filespec::vmspath($BZLIB_LIB);
    $BZLIB_BIN = VMS::Filespec::vmspath($BZLIB_BIN);
  }

  $BUILD_BZLIB = 1;

  print STDERR "Building internal libbz2 enabled\n" if $debugf ;

  print STDERR <<EOM if $debugf ;
INCLUDE	[$BZLIB_INCLUDE]
LIB	[$BZLIB_LIB]
BIN	[$BZLIB_BIN]

EOM
;

  print STDERR "Looks Good.\n" if $debugf;
}

ParseCONFIG('../config.in') ;

$::BZIP = 'bzip2'.$Config{exe_ext};
$::BZIP = $BZLIB_BIN ? catfile( $BZLIB_BIN, $::BZIP ) :
    -x $::BZIP ? rel2abs( $::BZIP ) : $::BZIP;

$ENV{PATH} .= ';' . getcwd() . '\\bzlib-src' if $^O =~ /win32/i; # just in case

$::debugf = $ENV{DEBUG};

