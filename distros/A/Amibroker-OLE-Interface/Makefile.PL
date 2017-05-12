use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Amibroker::OLE::Interface',
    AUTHOR           => q{Babu Prasad HP <bprasad@cpan.org>},
    VERSION_FROM     => 'lib/Amibroker/OLE/Interface.pm',
    ABSTRACT_FROM    => 'lib/Amibroker/OLE/Interface.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
		'Win32::OLE'	=> 0.1712,
		'Win32'			=> 0.51,
		'Path::Tiny' 	=> 0.061,
		'File::Slurp'	=> 9999.19,
		'IO::File'	 	=> 1.14,
		'Carp'			=> 0,
		
    },
	TEST_REQUIRES => {
		'Test::More' => 1.001014,
		'FindBin'	 => 0,
	},
	test => {
		'TESTS' => "t/*.t",
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Amibroker-OLE-Interface-*' },
);
