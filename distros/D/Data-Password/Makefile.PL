use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
        package MY;
        shift->SUPER::postamble . <<'MAKE';
distdir : README

README : Password.pm
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

MAKE
}

WriteMakefile(
    'NAME'	=> 'Data::Password',
    'VERSION_FROM' => 'Password.pm', # finds $VERSION
    PREREQ_PM    => {
       'Test::More' => 0,
       'Exporter'   => 0,
    },
    
    'dist' => {'COMPRESS' => 'gzip --best --force'},
);
