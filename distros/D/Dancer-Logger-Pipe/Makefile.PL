use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Logger::Pipe',
    AUTHOR              => q{Moshe Good <mgood@oanda.com>},
    VERSION_FROM        => 'lib/Dancer/Logger/Pipe.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Logger/Pipe.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer::Logger::Abstract' => 0,
        'Dancer::Config' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Logger-Pipe-*' },
);
