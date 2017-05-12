# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use strict;
use warnings;
use ExtUtils::MakeMaker;

unless (header_found()) {
   die <<"END";
ERROR: Can't find comedilib.h header file.

If the library is not installed, you will need to install it. if it is
installed somewhere other than /usr/include or /usr/local/include, you
need to set the following environment variables:

   COMEDILIB_LIBDIR should contain the path to the comedilib libraries
   COMEDILIB_INCDIR should contain the path to the comedilib header files

END
}

unless (lib_found()) {
   die <<"END";
ERROR: Can't find libcomedi.so library file.

If the library is not installed, you will need to install it. If it is
installed somewhere other than /usr/lib or /usr/local/lib, you need to
set the following environment variables:

   COMEDILIB_LIBDIR should contain the path to the comedilib libraries
   COMEDILIB_INCDIR should contain the path to the comedilib header files
   
END
}

sub header_found {
   foreach my $dir (qw(/usr/include /usr/local/include),
                    $ENV{COMEDILIB_INCDIR}) {
      return 1 if defined $dir && -e "$dir/comedilib.h";
   }
   return;
}

sub lib_found {
   foreach my $dir (qw(/usr/lib /usr/local/lib), $ENV{COMEDILIB_LIBDIR}) {
      return 1 if defined $dir && -e "$dir/libcomedi.so";
   }
   return;
}

my %options = %{ {
   NAME          => 'Comedi::Lib',
   AUTHOR        => 'Manuel Gebele <forensixs@gmx.de>',
   VERSION_FROM  => 'Lib.pm',
   ABSTRACT_FROM => 'Lib.pm',
   #($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => 'perl') : ()),
   PL_FILES      => {},
   PREREQ_PM     => {
      'Test::More'    => 0,
      'Carp'          => 0,
      'POSIX'         => 0,
      'InlineX::C2XS' => 0.14,
      'define'        => 0, # tested with define v.1.02
      'enum'          => 0, # tested with enum v.1.016
   },
   TYPEMAPS      => ['map/typemap'],
   LIBS          => '-lcomedi',
   #VERSION       => '0.24'
   dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
   #clean         => { FILES => 'Lib.bs Lib.o' }
}};

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
