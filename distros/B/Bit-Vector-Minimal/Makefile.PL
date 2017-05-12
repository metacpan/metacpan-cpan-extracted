use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Bit::Vector::Minimal',
	VERSION_FROM  => 'lib/Bit/Vector/Minimal.pm',
	ABSTRACT_FROM => 'lib/Bit/Vector/Minimal.pm',
	PREREQ_PM     => {},
	AUTHOR        => 'Tony Bowden <tmtm@cpan.org>',
);
