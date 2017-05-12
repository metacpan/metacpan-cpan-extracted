#!/usr/bin/perl
# -*- Mode: perl -*-
# tabstop = 3 spaces

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'				=> 'CLucene',
	'VERSION_FROM'		=> 'CLucene.pm',
	'PREREQ_PM'			=> {
		'Carp'				=> 1.0,
		'File::Path'		=> 1.0,
		},
	'PM'					=> {
		'CLucene.pm'	=> '$(INST_LIBDIR)/CLucene.pm',
		'CLuceneWrap.pm'	=> '$(INST_LIBDIR)/CLuceneWrap.pm',
		'CLuceneWrap.so'	=> '$(INST_ARCHLIB)/CLuceneWrap.so',
		},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CLucene.pm', # retrieve abstract from module
       AUTHOR     => 'Peter Edwards <peterdragon@users.sourceforge.net>') : ()),
	);

# Commands needed to build wrapper on Redhat Linux
#perl check.pl
#swig -perl clucene.i
#cc -c clucene_wrap.c -I../../src -I. -I/usr/lib/perl5/5.8.0/i386-linux-thread-multi/CORE -Dbool=char -D_REENTRANT -D_GNU_SOURCE -DTHREADS_HAVE_PIDS -DDEBUGGING -fno-strict-aliasing -I/usr/local/include -I/usr/include/gdbm -fpic
#cc -shared -L../../build/gcc/src/.libs -lclucene /usr/lib/clucene_dll.o clucene_wrap.o -o CLuceneWrap.so -lstdc++ -Xlinker -rpath /usr/lib -Xlinker -rpath /usr/local/lib

sub MY::top_targets
{
	my $this = shift;
	"all::   CLuceneWrap.so\n" . $this->MM::top_targets;
}

sub MY::dynamic
{
	"dynamic ::\n\n";
}

sub MY::postamble
{
	return <<EOM ;

OS := \$(shell perl ./check.pl -os)
PERLCORE := \$(shell perl check.pl -perl)

ifeq ("cygwin","\$(OS)") # cygwin
   LIBDIR=\$(HOME)/clucene.output/lib
   LINKOPTS=
else
   LIBDIR=../../build/gcc/src/.libs
   # this avoids needing to set LD_LIBRARY_PATH or LD_RUN_PATH at run time to find libclucene.so
   LINKOPTS=-Xlinker -rpath /usr/lib -Xlinker -rpath /usr/local/lib
endif

SWIG=swig
INCDIR=-I../../src -I.
INCCL=\$(INCDIR)
CFLAGS=\$(INCCL)
LDFLAGS=-lstdc++
LIBCL=-L\$(LIBDIR) -lclucene
LIBCLUCENE=-L\$(LIBDIR) -lclucene
SWIGCFLAGS=-D_REENTRANT -D_GNU_SOURCE -DTHREADS_HAVE_PIDS -DDEBUGGING -fno-strict-aliasing -I/usr/local/include -I/usr/include/gdbm -fpic
CLUCENEDLLO=/usr/lib/clucene_dll.o
CLUCENEDLLH=/usr/include/clucene_dllp.h

# build perl interface via DLL to CLucene shared library
# CLucene.pm -> CLuceneWrap.pm -> CLuceneWrap.so -> clucene_wrap.o -> clucene_dll.o -> libclucene.so

# build shareable perl/C library wrapper for DLL interface
# for linux
CLuceneWrap.so: \$(CLUCENEDLLO) \$(CLUCENEDLLH) clucene_wrap.o
	\${CC} -shared \$(LIBCLUCENE) \$(CLUCENEDLLO) clucene_wrap.o -o CLuceneWrap.so \$(LDFLAGS) \$(LINKOPTS)

# or for cygwin
cygwin: \$(CLUCENEDLLO) \$(CLUCENEDLLH) clucene_wrap.o
	\${CC} \${LIBCLUCENE} \$(LDFLAGS) /usr/bin/cygperl5_8_2.dll /usr/bin/cygcrypt-0.dll \$(CLUCENEDLLO) clucene_wrap.o -o CLuceneWrap.so

# swig perl/C wrapper to DLL interface
clucene_wrap.o: clucene.i clucene_perl.h
	\@perl check.pl
	\$(SWIG) -perl clucene.i
	\${CC} -c clucene_wrap.c \$(CFLAGS) -I\${PERLCORE} -Dbool=char \${SWIGCFLAGS}

# run test perl program against perl wrapper
testwrapper: CLuceneWrap.so
	LD_LIBRARY_PATH=\$(LIBDIR) perl clucene_test.pl

# test C wrapper to DLL interface, equivalent to perl test program but easier to debug against
testc: testc.o \$(CLUCENEDLLO)
	c++ -o testc testc.o \$(CLUCENEDLLO) \$(LIBCL) \$(LDFLAGS)

EOM
}

sub MY::clean
{
   return <<EOM ;

clean:
	rm -fr ./blib *.o testc pm_to_blib clucene_wrap.* CLuceneWrap.* swig.ver Makefile CLuceneWrap.pm

EOM
}
