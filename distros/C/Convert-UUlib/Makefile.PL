use ExtUtils::MakeMaker;

use Canary::Stability Convert::UUlib => 1;

sub MY::postamble {
    my $postamble =<<'END';

uulib/Makefile:
	cd uulib && ./configure --with-cc='$(CC)' --with-cflags='$(OPTIMIZE) $(CFLAGS) $(CCCDLFLAGS)'

clean::
	-cd uulib && make distclean

force:

$(MYEXTLIB): uulib/Makefile uulib/uulib.c force
	cd uulib && $(MAKE) all

END
}

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text UUlib.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'Convert::UUlib',
    'VERSION_FROM' => 'UUlib.pm',
    'MYEXTLIB'  => 'uulib/libuu$(LIB_EXT)',
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
    CONFIGURE_REQUIRES => {
       "ExtUtils::MakeMaker" => 6.52,
       "Canary::Stability"   => 0,
    },
);
