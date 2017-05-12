use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::UnixCrypt_XS',
    VERSION_FROM      => 'lib/Crypt/UnixCrypt_XS.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/UnixCrypt_XS.pm', # retrieve abstract from module
       AUTHOR         => 'Boris Zentner <bzm@2bz.de>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    OPTIMIZE => '-O3',
    'MYEXTLIB' => 'fcrypt/libfcrypt$(LIB_EXT)',
);
sub MY::postamble {'
$(MYEXTLIB): fcrypt/Makefile
	cd fcrypt && $(MAKE) $(PASSTHRU)
';
}
