use 5.008001; use strict; use warnings; use utf8;

use lib 'inc';
use Module::Build::InlineModule;

Module::Build::InlineModule->new(
    dist_name           => 'Alt-Acme-Math-XS-ModuleBuild',
    dist_abstract       => 'Math is HARD (faster)',
    dist_author         => 'Ingy döt Net <ingy@cpan.org>',
    dist_version        => '0.0.6',
    license             => 'perl',
    requires => {
        'Test::More' => 0,
    },
    configure_requires => {
        'Module::Build' => 0.42,
    },
    inline => {
        module => 'Acme::Math::XS',
    },
)->create_build_script();
