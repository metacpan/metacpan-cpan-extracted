use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Attribute::Profiled',
    'VERSION_FROM'	=> 'lib/Attribute/Profiled.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Attribute::Handlers => 0.70,
	Test::More          => 0,
	Benchmark::Timer    => 0.5,
	Hook::LexWrap       => 0.01,
    }, # e.g., Module::Name => 1.1
    'AUTHOR'		=> 'Tatsuhiko Miyagawa <miyagawa@bulknews.net>',
);
