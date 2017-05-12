use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Archive::Cpio',
	VERSION_FROM  => 'lib/Archive/Cpio.pm',
	ABSTRACT_FROM => 'lib/Archive/Cpio.pm',
        EXE_FILES     => ['bin/cpio-filter'],
	AUTHOR        => 'Pixel <pixel@rigaux.org>',
);
