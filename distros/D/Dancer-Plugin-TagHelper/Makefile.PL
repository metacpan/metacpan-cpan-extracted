use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME             => 'Dancer::Plugin::TagHelper',
    AUTHOR           => q{chenryn <rao.chenlin@gmail.com>},
    VERSION_FROM     => 'lib/Dancer/Plugin/TagHelper.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Plugin/TagHelper.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Dancer'          => 0,
        'HTML::TagHelper' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-TagHelper-*' },
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    repository => 'https://github.com/chenryn/Dancer-Plugin-TagHelper.git',
                },
                no_index => {directory => [qw/t/]},
            },
        )
    ), 
);
