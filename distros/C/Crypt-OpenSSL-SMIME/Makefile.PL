use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt::OpenSSL::SMIME',
    'DISTNAME' => 'Crypt-OpenSSL-SMIME',
    'VERSION_FROM' => 'SMIME.pm', # finds $VERSION
    'LIBS'	=> ['-lcrypto'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'TYPEMAPS'	=> ['perlobject.map' ],
    'MAN3PODS'  => {},
    'MAN1PODS'  => {},
    'PM'        => {'SMIME.pm' => '$(INST_LIBDIR)/SMIME.pm',},
);

sub MY::test {
'
test :: pure_all
	    $(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) test.pl
';
}
