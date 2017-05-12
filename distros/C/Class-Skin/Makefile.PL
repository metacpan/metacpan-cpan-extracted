use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Skin',
    'VERSION_FROM'	=> 'Skin.pm', # finds $VERSION
    'PREREQ_PM'		=> { Log::LogLite => 0.2 }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Skin.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
    'LIBS'		=> ['-lfl -lm'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'MYEXTLIB' => 'libskin/libskin$(LIB_EXT)',
    'OPTIMIZE' => '-O' # '-g' 
);


sub MY::postamble {
'
$(MYEXTLIB): libskin/Makefile
	cd libskin && $(MAKE) $(PASSTHRU)
';
}
