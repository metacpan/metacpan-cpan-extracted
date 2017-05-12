use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Attribute::Protected',
    'VERSION_FROM'	=> 'lib/Attribute/Protected.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Attribute::Handlers => 0.70,
	Test::More          => 0,
    }, # e.g., Module::Name => 1.1
    AUTHOR     => 'Tatsuhiko Miyagawa <miyagawa@bulknews.net>',
);
