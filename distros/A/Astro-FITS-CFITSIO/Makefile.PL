use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($inc, $libs);

FOUND_IT: {

  if (exists $ENV{CFITSIO}) {
    $inc = "-I$ENV{CFITSIO} -I$ENV{CFITSIO}/include";
    $libs = "-L$ENV{CFITSIO} -L$ENV{CFITSIO}/lib -lcfitsio -lm";
    last FOUND_IT;
  }

  if ( eval 'use ExtUtils::PkgConfig; 1; ' ) {
    my %pkg = eval { ExtUtils::PkgConfig->find( 'cfitsio' ); };
    if ( ! $@ ) {
      $inc = $pkg{cflags};
      $libs= $pkg{libs};
      last FOUND_IT;
    }
  }

  warn("CFITSIO environment variable not found, assuming /usr/local/cfitsio\n");
  $inc = "-I/usr/local/cfitsio";
  $libs = "-L/usr/local/cfitsio -lcfitsio -lm";

}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Astro::FITS::CFITSIO',
    'VERSION_FROM' => 'CFITSIO.pm', # finds $VERSION
    'LIBS'	=> [$libs],
    'INC'	=> $inc,
    'DEFINE'	=> '',
    'OBJECT' => 'CFITSIO.o util.o',
    'clean' => { FILES => "testprog.fit testprog/testprog.fit testprog/testprog.lis" },
);
