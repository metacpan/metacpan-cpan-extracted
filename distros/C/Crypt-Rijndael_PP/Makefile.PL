use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Crypt::Rijndael_PP',
    'VERSION_FROM'	=> 'Rijndael_PP.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'AUTHOR'		=> 'Christian Lackas, <delta@lackas.net>',
    'ABSTRACT'		=> 'Pure Perl implementation of Rijndael (AES)',
);

sub MY::postamble {
	'
all :: README

README: Rijndael_PP.pm
	$(PERL) -e \'use Pod::Text; pod2text "$<"\' > $@
'
}
