use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Plugin::Authentication::Credential::BBAuth',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Plugin/Authentication/Credential/BBAuth.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Test::MockObject'   => '1.01',
        'Yahoo::BBAuth'      => 0,
        'UNIVERSAL::require' => 0,
        'Catalyst'           => '5.50',
        'Catalyst::Plugin::Session'        => 0,
        'Catalyst::Plugin::Authentication' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Plugin-Authentication-Credential-BBAuth-*' },
);
