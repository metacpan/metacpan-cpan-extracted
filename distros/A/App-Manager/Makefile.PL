use ExtUtils::MakeMaker;
use POSIX;

if ($ARGV[0] =~ /^LIBDIR=(.*)$/) {
   $LIBDIR = $1;
} else {
   $LIBDIR = "/var/appman";
}

if ((uname)[0] !~ /linux/i) {
   print <<EOF;

WARNING: You are not running Linux. Better make sure your system supports
         dynamic linking, symbol versioning, gnu-binutils, libdl and RTLD_NEXT.
         glibc-2.1 might also be neccessary until I conditionalize versioning
         support.

EOF
}

sub MY::postamble {
   <<EOF

objclean :: clean
maintainer-clean :: realclean
distclean :: realclean
check :: test

all :: libtracer.\$(DLEXT)

install :: all
	\$(CP) libtracer.\$(DLEXT) \$(INSTALLSITEARCH)/libtracer.\$(DLEXT)
	\$(CHMOD) 755 \$(INSTALLSITEARCH)/libtracer.\$(DLEXT)

clean ::
	\$(RM_F) libtracer.\$(DLEXT)

replace.c: gensym
	\$(PERL) ./gensym

libtracer\$(OBJ_EXT): libtracer.c replace.c 
	\$(CC) -D_GNU_SOURCE -D_POSIX_SOURCE -c -o \$@ libtracer.c

libtracer.\$(DLEXT): libtracer\$(OBJ_EXT)
	ld -o \$@ -shared \$^ -ldl --version-script Versions.def
	\$(CHMOD) \$(PERM_RWX) \$@

EOF
}

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'App::Manager',
    'VERSION_FROM' => 'Manager.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> "'-DLIBTRACER_SO=\"\$(INSTALLSITEARCH)/libtracer.\$(DLEXT)\"' '-DLIBDIR=\"$LIBDIR\"'",
    'EXE_FILES'	=> ['appman'],
    'INC'	=> '',
    'PREREQ_PM'	=> {
		    File::Spec		=> 0.7,
                    Storable		=> 0.6,
		   },
    'clean'	=> { FILES => "Versions.def replace.c" },
);

