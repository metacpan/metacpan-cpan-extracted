use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Batch::Interpreter',
    AUTHOR           => q{Ralf Neubauer <ralf@strcmp.de>},
    VERSION_FROM     => 'lib/Batch/Interpreter.pm',
    ABSTRACT_FROM    => 'lib/Batch/Interpreter.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Test::Differences' => 0,
    },
    PREREQ_PM => {
	'Term::ReadLine' => 0,
	'Getopt::Long' => 0,
	'Data::Dump' => 0,
	'Cwd' => 0,
	'Time::HiRes' => 0,
	'List::MoreUtils' => 0,
	'File::DosGlob' => 0,
	'File::Spec' => 0,
	'File::Spec::Win32' => 0,
	'File::Temp' => 0,
	'File::Find' => 0,
	'File::Copy' => 0,
	'Clone' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Batch-Interpreter-*' },
);
