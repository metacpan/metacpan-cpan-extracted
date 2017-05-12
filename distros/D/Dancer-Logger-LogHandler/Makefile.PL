use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Logger::LogHandler',
    AUTHOR              => q{Franck Cuny <franck@lumberjaph.net>},
    VERSION_FROM        => 'lib/Dancer/Logger/LogHandler.pm',
    ABSTRACT            => 'Dancer logger engine for Log::Handler',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer'       => 1.123,
        'Log::Handler' => 0,
        'Test::More'   => 0,
        'Test::Output' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Logger-LogHandler-*' },
);
