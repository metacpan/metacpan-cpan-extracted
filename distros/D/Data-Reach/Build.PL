use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Reach',
    license             => 'perl',
    dist_author         => q{Laurent Dami <dami@cpan.org>},
    dist_version_from   => 'lib/Data/Reach.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    test_requires => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
    },
    requires => {
        perl                => 5.010,
        'overload'          => 0,
        'Carp'              => 0,
        'Scalar::Util'      => 0,
    },
    add_to_cleanup     => [ 'Data-Reach-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Data-Reach',
       }
     },

);

$builder->create_build_script();
