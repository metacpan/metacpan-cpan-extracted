use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

our $VERSION = 0.03;

WriteMakefile(
    NAME             => 'Acme::Array::MaxSize',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => 'lib/Acme/Array/MaxSize.pm',
    ABSTRACT_FROM    => 'lib/Acme/Array/MaxSize.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        parent => 0,
    },
    META_MERGE => { resources
        => { repository => 'https://github.com/choroba/Acme-Array-MaxSize' },
             provides => { 'Acme::Array::MaxSize' => {
                                 file => 'lib/Acme/Array/MaxSize.pm',
                                 version => $VERSION,
                             },
                         },
    },
    macro => { TARFLAGS => '--format=ustar -cvf' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-Array-MaxSize-*' },
);

sub MY::postamble {
    return "version-bump:\n\tperl-reversion --bump Makefile.PL lib/Acme/Array/MaxSize.pm\n"
}
