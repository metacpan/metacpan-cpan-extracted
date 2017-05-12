use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Nopaste::Service::Pastedance',
    license             => 'perl',
    dist_author         => q{Danijel Tasov <data@cpan.org>},
    dist_version_from   => 'lib/App/Nopaste/Service/Pastedance.pm',
    dist_abstract       => 'Add Pastedance service to App::Nopaste',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'App::Nopaste' => 0,
    },
    add_to_cleanup      => [ 'App-Nopaste-*' ],
    meta_merge => {
        resources => {
            repository => 'http://github.com/datamuc/App-Nopaste-Service-Pastedance',
        },
    },
);

$builder->create_build_script();
