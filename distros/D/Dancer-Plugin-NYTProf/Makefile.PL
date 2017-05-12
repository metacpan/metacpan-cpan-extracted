use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::NYTProf',
    AUTHOR              => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM        => 'lib/Dancer/Plugin/NYTProf.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/NYTProf.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'Dancer'         => 1.3060,
        'Devel::NYTProf' => 0,
        'File::stat'     => 0,
        'File::Temp'     => 0,
        'File::Which'    => 0,
        'Capture::Tiny'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-NYTProf-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => {
                web => 'https://github.com/bigpresh/Dancer-Plugin-NYTProf/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/bigpresh/Dancer-Plugin-NYTProf.git',
                web  => 'https://github.com/bigpresh/Dancer-Plugin-NYTProf',
            },
        },
    },
);
