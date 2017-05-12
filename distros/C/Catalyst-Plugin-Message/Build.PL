use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::Message',
    license             => 'perl',
    dist_author         => 'Chunzi <chunzi@cpan.org>',
    dist_version_from   => 'lib/Catalyst/Plugin/Message.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Catalyst-Plugin-Message-*' ],
);

$builder->create_build_script();
