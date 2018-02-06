use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::ShellCheckWiki',
    AUTHOR           => q{Felix Tubiana <felixtubiana@gmail.com>},
    VERSION_FROM     => 'lib/App/ShellCheckWiki.pm',
    ABSTRACT_FROM    => 'lib/App/ShellCheckWiki.pm',
    LICENSE          => 'artistic_1',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    EXE_FILES        => ['bin/shellcheckwiki'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'WWW::Mechanize'    => '1.86',
        'Term::ANSIColor'   => '4.06',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-ShellCheckWiki-*' },

    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/xxfelixxx/shellcheckwiki.git',
                web  => 'https://github.com/xxfelixxx/shellcheckwiki',
            },
        }})
     : ()
       ),
);
