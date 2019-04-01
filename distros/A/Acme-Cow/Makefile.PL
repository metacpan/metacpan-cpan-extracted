use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::Cow',
    'VERSION_FROM'	=> 'Cow.pm', # finds $VERSION
    'PREREQ_PM'		=> { Text::Template => 0, },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Cow.pm', # retrieve abstract from module
       AUTHOR     => 'Tony Monroe <tmonroe plus perl at nog dot net>') : ()),
    'EXE_FILES' => [ qw(cowsay cowthink cowpm) ],
);

sub MY::postamble
{
    return <<'EOM';
install-cows ::
	@echo Installing cow files in $(PREFIX)/share/cows
	$(MKPATH) $(PREFIX)/share/cows
	$(CP) cows/* $(PREFIX)/share/cows
	@echo Remember to add $(PREFIX)/share/cows to your COWPATH!
EOM
}
