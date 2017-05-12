use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer2::Logger::Syslog',
    AUTHOR              => q{Andy Beverley <andy@andybev.com>},
    VERSION_FROM        => 'lib/Dancer2/Logger/Syslog.pm',
    ABSTRACT_FROM       => 'lib/Dancer2/Logger/Syslog.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Exporter'              => 0,
        'HTTP::Request::Common' => 0,
        'Plack'                 => '1.0029',    # OO-style Plack::Test
        'Plack::Test'           => 0,
        'Test::Deep'            => 0,
        'Test::More'            => 0,
        'Test::Warnings'        => 0,
    },
    PREREQ_PM => {
        'Dancer2' => 0.151,
        "File::Basename" => 0,
        "Moo" => 0,
        "Sys::Syslog" => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer2-Logger-Syslog-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/abeverley/Dancer2-Logger-Syslog',
            bugtracker => 'https://github.com/abeverley/Dancer2-Logger-Syslog/issues',
            homepage   => 'https://github.com/abeverley/Dancer2-Logger-Syslog/',
        },
    },

);
