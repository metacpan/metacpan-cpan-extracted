use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Logger::ColorConsole',
    AUTHOR              => q{Alberto Simoes <ambs@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/Logger/ColorConsole.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Logger/ColorConsole.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More'      => 0,
                  'Dancer'          => '1.3060',
                  'Term::ANSIColor' => '4.00',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Logger-ColorConsole-*' },
    META_MERGE =>
          {
           "meta-spec" => { version => 2 },
           resources =>
           {
            repository => 
            {
             type => 'git',
             web => 'https://github.com/ambs/Dancer-Logger-ColorConsole',
            },
           },
          },
);
