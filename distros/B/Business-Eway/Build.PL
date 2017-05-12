use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Business::Eway',
    license             => 'perl',
    dist_author         => q{eWAY Europe Ltd <support@eway.co.uk>},
    dist_version_from   => 'lib/Business/Eway.pm',
    build_requires => {
        'Test::More' => 0,
        'URI::Escape' => 0,
        'LWP::UserAgent' => 0,
        'Crypt::SSLeay' => 0,
        'XML::Simple' => 0,
    },
    add_to_cleanup      => [ 'Business-Eway-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
