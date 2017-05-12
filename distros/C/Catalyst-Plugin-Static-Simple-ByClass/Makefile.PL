use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Catalyst::Plugin::Static::Simple::ByClass',
    AUTHOR        => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM  => 'lib/Catalyst/Plugin/Static/Simple/ByClass.pm',
    ABSTRACT_FROM => 'lib/Catalyst/Plugin/Static/Simple/ByClass.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'                       => 0,
        'Catalyst::Runtime'                => 5.8,
        'Path::Class'                      => 0,
        'Catalyst::Plugin::Static::Simple' => 0.29,
        'Class::Inspector'                 => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Plugin-Static-Simple-ByClass-*' },
);
