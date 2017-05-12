use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Business::BR::CEP',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/Business/BR/CEP.pm',
    requires => {
        'parent'     => 0,
        'Test::More' => '0.88',
    },
    add_to_cleanup      => [ 'Business-BR-CEP-*' ],
);

$builder->create_build_script();
