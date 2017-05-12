use ExtUtils::MakeMaker;
use Config ;

BEGIN {
  eval { require File::Spec::Functions ; File::Spec::Functions->import( catfile rel2abs ) } ;
  *catfile = sub { return join( '/', @_ ) } if $@;
}

require VMS::Filespec if $^O eq 'VMS';

#$Verbose = 1;

WriteMakefile(
	      NAME => 'Compress::Bzip2::internal_bzlib',
	      SKIP => [qw(all static_lib static dynamic dynamic_lib)],
	      clean             => {
		FILES=>
		    join(' ', map { catfile( split( /\//, $_ ) ) }
			 qw(libbz2$(LIB_EXT) bzip2$(EXE_EXT) t/??-tmp*)
			 )
		  },

);

#libbz2$(LIB_EXT): $(O_FILES)

package MY;
use File::Basename;

sub top_targets {
  my $make = $Config::Config{make};
  $make = basename($make);
  if ($^O =~ /win32/i) {
    $make =~ s/.exe$//i;
  }
  my $cc = $Config::Config{cc};
  my $objects = join( ' ', map { $_.'$(OBJ_EXT)' } qw(blocksort huffman crctable randtable compress decompress bzlib) );
  my $ar_args = $cc eq 'cl' && $^O =~ /win32/i ? '-out:$@' : '$(AR_STATIC_ARGS) $@';

  my $out='
all ' . ( $^O =~ /win32/i && $make eq 'dmake' ? ':' : '::' ) . ' static

pure_all ' . ( $^O =~ /win32/i && $make eq 'dmake' ? ':' : '::' ) . ' static

static ' . ( $^O =~ /win32/i && $make eq 'dmake' ? ':' : '::' ) . ' libbz2$(LIB_EXT) bzip2$(EXE_EXT)

libbz2$(LIB_EXT): ' . $objects . '
	$(AR) ' . $ar_args . ' ' . ( $^O =~ /win32/i && $make eq 'nmake' ? $objects : '$^' ) . ' && $(RANLIB) $@

' .
#'bzip2$(EXE_EXT) ' . ( $^O =~ /win32/i && $make eq 'nmake' ? '::' : ':' ) . ' bzip2$(OBJ_EXT) libbz2$(LIB_EXT)' . '
#';

#   ( $^O =~ /win32/i && $make eq 'nmake' ?
#       'bzip2$(EXE_EXT): bzip2.c libbz2$(LIB_EXT)
# 	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -obzip2$(EXE_EXT) bzip2.c $(LDFLAGS) libbz2$(LIB_EXT)' :
#       'bzip2$(EXE_EXT): bzip2$(OBJ_EXT) libbz2$(LIB_EXT)' )

 ( $^O =~ /win32/i ? 
   ($make eq 'nmake' && $cc eq 'cl') ?
      'bzip2$(EXE_EXT): bzip2.c libbz2$(LIB_EXT)
	$(CC) /MD -o bzip2$(EXE_EXT) bzip2.c libbz2$(LIB_EXT)'
    : 'bzip2$(EXE_EXT): bzip2.c libbz2$(LIB_EXT)
	$(CC) -o bzip2$(EXE_EXT) bzip2.c libbz2$(LIB_EXT)'
  : 'bzip2$(EXE_EXT): bzip2$(OBJ_EXT) libbz2$(LIB_EXT)' ) . '
';

if ($ExtUtils::MakeMaker::VERSION >= 7.16) { #https://rt.cpan.org/Ticket/Display.html?id=117800
#when it will be fixed in EUMM, '<=' condition should be added
    $out .= '

dynamic ::
	$(NOECHO) $(NOOP)

';
}
  return $out;
}
