use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::CriticalPath',
    AUTHOR              => q{Ded MedVed <dedmedved@cpan.org>},
    VERSION_FROM        => 'lib/Algorithm/CriticalPath.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/CriticalPath.pm',
    MIN_PERL_VERSION    => 5.8.0,
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES => [],
    PREREQ_PM => {
        'Data::Printer'                 => 0,
        'Test::More'                    => 0,
        'Test::Deep'                    => 0,
        'Test::Exception'               => 0,
        'Carp'                          => 0,
        'IPC::System::Simple'           => 0,   # everything needs this ( on bsd anyway)
        'Mouse'                         => 0,
        'Graph'                         => 0.94,
        'version'                       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SSIS-FileDependencies-*' },
);



