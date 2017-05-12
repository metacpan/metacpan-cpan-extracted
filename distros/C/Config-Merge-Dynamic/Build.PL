use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::Merge::Dynamic',
    license             => 'perl',
    dist_author         => q{Meettya <meettya@cpan.org>},
    dist_version_from   => 'lib/Config/Merge/Dynamic.pm',
    configure_requires 	=> { 'Module::Build' => 0.38 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' 			=> 5.008,
        'parent'		=> 0,
        'Carp' 			=> 1.20,
        'Config::Merge' => 1.01,
        'YAML::XS'		=> 0.35,
    },
    add_to_cleanup      => [ 'Config-Merge-Dynamic-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
    	resources => {
      		repository  => 'https://github.com/Meettya/Config-Merge-Dynamic/'
    	}
    }
);

$builder->create_build_script();
