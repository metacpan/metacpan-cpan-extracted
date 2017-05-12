use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CLI::Framework',
    AUTHOR              => 'Karl Erisman <kerisman@cpan.org>',
    VERSION_FROM        => 'lib/CLI/Framework.pm',
    ABSTRACT            => 'Build standardized, flexible, testable command-line applications',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES    => {},
    PREREQ_PM   => {
        'Test::More'                    => 0,
        'File::Spec'                    => 0,
        'Carp'                          => 0,
        'Getopt::Long::Descriptive'     => 0,
        'Class::Inspector'              => 0,
        'Term::ReadLine'                => 0,
        'Text::ParseWords'              => 0,
        'Exception::Class'              => 0,
        'Exception::Class::TryCatch'    => 0,
    },
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean   => { FILES => 'CLI::Framework-*' },
);
