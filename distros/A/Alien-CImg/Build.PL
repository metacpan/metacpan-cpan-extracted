use strict;
use warnings;

use Alien::Base::ModuleBuild '0.025';

my $builder = Alien::Base::ModuleBuild->new (
    module_name => 'Alien::CImg',
    license => 'mit',
    configure_requires => {
        'Archive::Zip' => '1.59',
        'Alien::Base' => '0.025',
        'Module::Build' => '0.38',
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Alien::Base' => '0.025',
    },
    alien_name => 'cimg',
    alien_repository => {
        protocol => 'http',
        host => 'cimg.eu',
        location => '/files/',
        exact_path  => 'CImg_latest.zip',
    },
    alien_build_commands => [],
    alien_test_commands => [],
    alien_install_commands => [
        'mkdir -p %s/include',
        'cp CImg.h %s/include'
    ]
);


$builder->create_build_script;
