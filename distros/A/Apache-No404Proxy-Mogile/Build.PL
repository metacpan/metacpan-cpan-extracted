use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache::No404Proxy::Mogile',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@gerakines.net>',
    dist_version_from   => 'lib/Apache/No404Proxy/Mogile.pm',
    requires => {
        'Apache::No404Proxy' => 0,
        'MogileFS' => 0,
        'LWP::UserAgent' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 'Apache-No404Proxy-Mogile-*' ],
);

$builder->create_build_script();
