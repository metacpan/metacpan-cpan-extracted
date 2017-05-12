use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Command::Interactive',
    AUTHOR           => q{binary.com <perl@binary.com>},
    VERSION_FROM     => 'lib/Command/Interactive.pm',
    ABSTRACT_FROM    => 'lib/Command/Interactive.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::NoWarnings' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'Moose'      => 0,
        'Expect'      => 0,
        'List::Util'  => '1.33',
      },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Command-Interactive-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'https://github.com/binary-com/perl-command-interactive.git',
                    web => 'https://github.com/binary-com/perl-command-interactive',
                  },
            }})
     : ()
    ),
);
