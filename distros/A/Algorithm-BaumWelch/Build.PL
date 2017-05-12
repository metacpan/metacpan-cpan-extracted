use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::BaumWelch',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Algorithm/BaumWelch.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp'                      => '1.08', 
        'Math::Cephes'              => '0.47', 
        'List::Util'                => '1.19', 
        'Text::SimpleTable'         => '2.0',
    },
    add_to_cleanup      => [ 'Algorithm-BaumWelch-*' ],
);

$builder->create_build_script();
