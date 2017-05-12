use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt-DES_PP',
    'VERSION_FROM' => 'DES_PP.m4', # finds $VERSION
);

sub MY::postamble {
   ' 
all :: lib/Crypt/DES_PP.pm README

M4 = m4

lib/Crypt/DES_PP.pm: DES_PP.m4
	$(M4) -P $< >$@

README: DES_PP.m4
	$(PERL) -e \'use Pod::Text; pod2text "$<"\' >$@

'
}
