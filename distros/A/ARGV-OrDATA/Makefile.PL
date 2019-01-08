use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ARGV::OrDATA',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => 'lib/ARGV/OrDATA.pm',
    ABSTRACT_FROM    => 'lib/ARGV/OrDATA.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'FindBin'    => '0',
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    macro => { TARFLAGS => '--format=ustar -cvf' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ARGV-OrDATA-*' },
    META_MERGE => {
        resources => { repository => 'https://github.com/choroba/argv-ordata' },
    },
);
