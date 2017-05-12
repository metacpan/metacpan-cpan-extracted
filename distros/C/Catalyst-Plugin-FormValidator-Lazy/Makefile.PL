use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Plugin::FormValidator::Lazy',
    AUTHOR              => 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>',
    VERSION_FROM        => 'lib/Catalyst/Plugin/FormValidator/Lazy.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Plugin/FormValidator/Lazy.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Catalyst::Runtime'   => 5.70,
        'Data::FormValidator' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Plugin-FormValidator-Lazy-*' },
);
