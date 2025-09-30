use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::Writer',
    AUTHOR              => 'Volodymyr Pidgornyi <vp@dtel-ix.net>',
    VERSION_FROM        => 'lib/Config/Writer.pm',
    # ABSTRACT_FROM       => 'lib/Config/Writer.pm',
    ABSTRACT            => 'module to write configuration files in an easy and safe way',
    LICENSE             => 'apache_2_0',
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/kornix/perl-Config-Writer.git',
                 web  => 'https://github.com/kornix/perl-Config-Writer',
             },
         },
    },
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-Writer-*' },
);
