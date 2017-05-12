use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Authen::Smb',
    'VERSION_FROM' => 'Smb.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'MYEXTLIB'  => 'smbval/smbvalid$(LIB_EXT)',
    'OPTIMIZE'  => '-g',
);

sub MY::postamble {
'
$(MYEXTLIB): smbval/Makefile
	cd smbval && $(MAKE) $(PASTHRU)
';
}
