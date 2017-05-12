use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Plugin::Acme::Scramble',
    AUTHOR              => 'Ashley Pond V <ashley@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Plugin/Acme/Scramble.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        "Catalyst" => "5.6",
        "HTML::TokeParser" => 2,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Plugin-Acme-Scramble-*' },
);
