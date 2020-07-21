#! perl -w

use strict;
use 5.008001;

use ExtUtils::MakeMaker;
use Config ;
use File::Copy ;

BEGIN {
  eval { require File::Spec::Functions ; File::Spec::Functions->import( catfile rel2abs ) } ;
  *catfile = sub { return join( '/', @_ ) } if $@;
}

require VMS::Filespec if $^O eq 'VMS';

my $BZLIB_BIN ;
my $BZLIB_LIB ;
my $BZLIB_INCLUDE ;
my $BUILD_BZLIB = 0; # override with env BUILD_BZLIB=1

ParseCONFIG() ;

my %Bzip2 = ( pm => catfile( qw( lib Compress Bzip2.pm ) ),
	      lib => catfile( 'bzlib-src', 'libbz2'.$Config{_a} ) );

my $dlflags = $Config{ccdlflags}; # RT 105096
if ($Config{ld} ne $Config{cc} and $Config{ld} =~ m{^(.*/)?\w*ld\w*$}) {
  my @flags;
  for (split m/\s+/ => $dlflags) {
    s/^-Wl,(-+[-\w]+),/$1 / or s/^-Wl,//;
    push @flags, $_;
  }
  $dlflags = join " " => @flags;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME              => 'Compress::Bzip2',
  VERSION_FROM      => $Bzip2{pm},
  PREREQ_PM         => {
    'constant'   => 1.04, # for constant => {}
    'Test::More' => 0,
    'File::Spec' => 0,
    'File::Copy' => 0,
    'Config'     => 0,
    'Carp'       => 0,
    'Getopt::Std'=> 0,
    'Fcntl'      => 0,
  },
  XS	 	=> { 'Bzip2.xs'    => 'Bzip2.c' },
  ($] >= 5.005 ?
   (ABSTRACT_FROM  => $Bzip2{pm},
    AUTHOR         => 'Rob Janes <arjay@cpan.org>') : ()),
  LIBS             => $BUILD_BZLIB ? [] : [ $BZLIB_LIB ? "-L$BZLIB_LIB -lbz2" : '-lbz2' ],
  # ccdlflags needed for -R [cpan #68572, #105096]
  LDDLFLAGS         => $Config{lddlflags} . " " . $dlflags,
  INC               => $BUILD_BZLIB ? '-Ibzlib-src' : $BZLIB_INCLUDE ? "-I$BZLIB_INCLUDE" : '',
  clean             => {
    FILES=>
      join(' ',
	   map { catfile( split( /\//, $_ ) ) }
	   qw( const-c.inc const-xs.inc junk* bztest show_bzversion t/???-tmp-* ))
  },
  depend            => { 'Makefile'	  => 'config.in' },
  NORECURS          => $BUILD_BZLIB ? 0 : 1,
  ($BUILD_BZLIB ? ( MYEXTLIB       => $Bzip2{lib} ) : ()),
  ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
   ('LICENSE'     => 'perl',
    'META_MERGE'  =>
    {"recommends" =>
     {
       'Compress::Zlib'       => '1.19',
       'IO::Compress::Bzip2'  => '2.094',
       'Compress::Raw::Bzip2' => '2.094',
     },
     resources =>
     {
       license     => 'http://dev.perl.org/licenses/',
       repository  => 'https://github.com/rurban/Compress-Bzip2',
     },
    }
   ) : ()),
  SIGN  => 1,
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(BZ_CONFIG_ERROR BZ_DATA_ERROR BZ_DATA_ERROR_MAGIC
		 BZ_FINISH BZ_FINISH_OK BZ_FLUSH BZ_FLUSH_OK BZ_IO_ERROR
		 BZ_MAX_UNUSED BZ_MEM_ERROR BZ_OK BZ_OUTBUFF_FULL
		 BZ_PARAM_ERROR BZ_RUN BZ_RUN_OK BZ_SEQUENCE_ERROR
		 BZ_STREAM_END BZ_UNEXPECTED_EOF));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Compress::Bzip2',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub MY::postamble {
  !$BUILD_BZLIB ? '' :
'
$(MYEXTLIB): '.catfile( qw( bzlib-src Makefile ) ).'
	cd bzlib-src && $(MAKE) $(PASSTHRU)
';
}

sub ParseCONFIG {
  my ($k, $v) ;
  my @badkey = () ;
  my %Info = () ;
  my @Options = qw( BZLIB_INCLUDE BZLIB_LIB BUILD_BZLIB BZLIB_BIN ) ;
  my %ValidOption = map {$_, 1} @Options ;
  my %Parsed = %ValidOption ;
  my $CONFIG = 'config.in' ;

  print "Parsing $CONFIG...\n" ;

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

  print "Unknown keys in $CONFIG ignored [@badkey]\n"
      if @badkey ;

  $BZLIB_INCLUDE = $ENV{'BZLIB_INCLUDE'} || $Info{'BZLIB_INCLUDE'} ;
  $BZLIB_LIB = $ENV{'BZLIB_LIB'} || $Info{'BZLIB_LIB'} ;
  $BZLIB_BIN = $ENV{'BZLIB_BIN'} || $Info{'BZLIB_BIN'} ;

  if ($^O eq 'VMS') {
    $BZLIB_INCLUDE = VMS::Filespec::vmspath($BZLIB_INCLUDE);
    $BZLIB_LIB = VMS::Filespec::vmspath($BZLIB_LIB);
    $BZLIB_BIN = VMS::Filespec::vmspath($BZLIB_BIN);
  }

  my $x = defined($ENV{BUILD_BZLIB}) ? $ENV{BUILD_BZLIB} : $Info{BUILD_BZLIB};
  $x = 'Test' if !defined($x);

  if ( $x =~ /^yes|on|true|1$/i ) {
    $BUILD_BZLIB = 1;

    print "Building internal libbz2 enabled\n" ;
  }
  elsif ( $x =~ /^test$/i ) {
    undef $BUILD_BZLIB;

    ## prefix libpth locincpth
    my $command = $Config{cc} .
	' '. $Config{ccflags} .
	( $BZLIB_INCLUDE ? " -I$BZLIB_INCLUDE" : '' ) .
	' '. $Config{ccdlflags} .
	' '. $Config{ldflags} .
	' -o show_bzversion show_bzversion.c' .
	( $BZLIB_LIB ? " -L$BZLIB_LIB" : '' ) .
	' -lbz2';

    #print "command $command\n";
    if ( !system( $command ) ) {
      if ( -x 'show_bzversion' && -s 'show_bzversion' ) {
	my $version = `./show_bzversion`;
	if ( $version ) {
	  chomp $version;
	  $BUILD_BZLIB = 0;
	  print "found bzip2 $version ".($BZLIB_LIB ? "in $BZLIB_LIB" : 'installed')."\n";
	}
	else {
	  $BUILD_BZLIB = 1;
	  print "compile command '$command' failed\n";
	  print "system bzip2 not useable, building internal libbz2\n";
	}
      }
      else {
	$BUILD_BZLIB = 1;
	print "compile command '$command' failed\n";
	print "system bzip2 not useable, building internal libbz2\n";
      }
    }
    else {
      $BUILD_BZLIB = 1;
      print "compile command '$command' failed\n";
      print "system bzip2 not found, building internal libbz2\n";
    }
  }

  print <<EOM if 0 ;
INCLUDE	[$BZLIB_INCLUDE]
LIB	[$BZLIB_LIB]
BIN	[$BZLIB_BIN]

EOM
;

  print "Looks Good.\n" ;

}
