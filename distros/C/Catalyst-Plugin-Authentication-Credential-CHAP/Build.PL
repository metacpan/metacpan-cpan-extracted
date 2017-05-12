use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::Authentication::Credential::CHAP',
    license             => 'perl',
    create_makefile_pl  => 'traditional',
    dist_author         => 'Renaud Drousies <rdrousies@cpan.org>',
    dist_version_from   => 'lib/Catalyst/Plugin/Authentication/Credential/CHAP.pm',
    build_requires => {
        'Test::More' => 0,
        'Digest' => 0,
        'Catalyst' => '>= 5.65',
        'Catalyst::Plugin::Session' => 0,
        'Catalyst::Plugin::Authentication::Credential::Password' => 0
    },
    add_to_cleanup      => [ 'Catalyst-Plugin-Authentication-Credential-CHAP-*' ],
);

$builder->create_build_script();
