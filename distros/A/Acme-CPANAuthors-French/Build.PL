use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::CPANAuthors::French',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Acme/CPANAuthors/French.pm',
    requires => {
        'perl'              => '5.008',
        'Acme::CPANAuthors' => '0.04',
    },
    build_requires => {
        'Test::More'        => 0,
    },
    add_to_cleanup      => [ 'Acme-CPANAuthors-French-*' ],
);

$builder->create_build_script();
