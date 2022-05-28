use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::Passphrase',
    AUTHOR           => q{Henk van Oers <hvo.pm@xs4all.nl>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/Passphrase.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Passphrase.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION => 5.008001,
    PL_FILES         => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer2'    => '0.200000',
        'Digest::Bcrypt' => 0,
        'Digest::SHA' => 5.74,
        'Data::Entropy' => 0.007,
        'version' => 0.77,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Passphrase-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/PerlDancer/Dancer2-Plugin-Passphrase',
            bugtracker => 'https://github.com/PerlDancer/Dancer2-Plugin-Passphrase/issues',
            homepage   => 'https://github.com/PerlDancer/Dancer2-Plugin-Passphrase/',
        },
    },
);
