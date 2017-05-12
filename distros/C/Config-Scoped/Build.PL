use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Config::Scoped',
    create_readme => 1,
    license       => 'perl',
    dist_author   => 'Karl Gaissmaier <karl.gaissmaier (at) uni-ulm.de>',
    requires      => {
        'Parse::RecDescent' => '1.94',
        Error               => 0,
        Storable            => 0,
        Safe                => 0,
        Carp                => 0,
        'File::Spec'        => 0,
        'File::Basename'    => 0,
        'Digest::MD5'       => 0,
    },
    build_requires => {
        'Module::Build' => '0',
        'Test::More'    => '0',
    },

    configure_requires => { 'Module::Build' => 0, },
    add_to_cleanup => [qw/Config-Scoped-* Makefile* Debian_CPANTS.*/],
);

$builder->create_build_script();
