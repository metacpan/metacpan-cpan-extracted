use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Validate::VIN',
    license             => 'perl',
    dist_author         => q{collin seaton <cseaton@cpan.org>},
    dist_version_from   => 'lib/Data/Validate/VIN.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.008,
    },
   add_to_cleanup      => [ 'Data::Validate-VIN-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
