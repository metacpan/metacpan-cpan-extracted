use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Mojo::Template',
    AUTHOR           => q{Михаил Че (Mikhail Che) <mche[-at-]cpan.org>},
    VERSION_FROM     => 'lib/DBIx/Mojo/Template.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Mojo/Template.pm',
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
        'Hash::Merge'=>0.200,
        'Clone'=>0,
        'Mojolicious'=>6.00,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
          repository => {
            type => 'git',
            url => 'git://github.com/mche/DBIx-Mojo-Template.git',
            web => 'https://github.com/mche/DBIx-Mojo-Template',
          },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean => { FILES => 'DBIx-Mojo-Template-*' },
);
