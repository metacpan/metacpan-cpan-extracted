use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CGI::Authent',
    'VERSION_FROM' => 'Authent.pm', # finds $VERSION
#    'PM' => {'Authent.config.pl' => '$(INST_LIBDIR)/Authent.config.pl'},
    'NEEDS_LINKING' => 0,
	'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
   ($] ge '5.005')
    ? (
     'AUTHOR' => 'Jan Krynicky (Jenda@Krynicky.cz)',
     'ABSTRACT' => 'Ask for HTTP authentification unless condition holds',
    )
    : (),
);
