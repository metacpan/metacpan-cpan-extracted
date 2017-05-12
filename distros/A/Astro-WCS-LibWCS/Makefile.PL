use ExtUtils::MakeMaker;

my ($inc, $libs);

FOUND_IT : {

  if (exists $ENV{WCSTOOLS}) {
    $inc = "-I$ENV{WCSTOOLS}/libwcs";
    $libs = "-L$ENV{WCSTOOLS}/libwcs -lwcs -lm";
    last FOUND_IT;
  }

  if (exists $ENV{WCSTOOLS_INC} && exists $ENV{WCSTOOLS_LIB} ) {
    $inc = $ENV{WCSTOOLS_INC};
    $libs = $ENV{WCSTOOLS_LIB};
    last FOUND_IT;
  }

  if ( eval 'use ExtUtils::PkgConfig; 1; ' ) {
    my %pkg = eval { ExtUtils::PkgConfig->find( 'wcstools' ); };
    if ( ! $@ ) {
      $inc = $pkg{cflags};
      $libs = $pkg{libs};
      last FOUND_IT;
    }
  }

  warn("WCSTOOLS environment variable not found, assuming /usr/local/wcstools\n");
  $inc = "-I/usr/local/wcstools/libwcs";
  $libs = "-L/usr/local/wcstools/libwcs -lwcs -lm";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Astro::WCS::LibWCS',
	      'VERSION_FROM' => 'LibWCS.pm', # finds $VERSION
	      'LIBS' => [$libs],
	      'INC' => $inc,
	      'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
	      'OBJECT' => 'LibWCS.o util.o',
	     );
