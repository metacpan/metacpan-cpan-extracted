use strict;
use warnings;

use Module::Build 0.28;

use lib 'inc';
use My::ModuleBuild;

my $builder = My::ModuleBuild->new(
    module_name => 'Alien::libsndfile',
    license => 'mit',
    configure_requires => {
        'Alien::Base' => 0,
        'Module::Build' => 0.28,
    },
    requires => {
        'perl' => '5.8.1',
        'Alien::Base' => 0,
    },
    alien_name => 'libsndfile',
    alien_repository => {
        # http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.27.tar.gz
        protocol => "http",
        host => "www.mega-nerd.com",
        location => "/libsndfile/files",
        exact_filename  => 'libsndfile-1.0.27.tar.gz',
    },
    alien_build_commands => [
        '%c --prefix=%s',
        'make',
        'make install'
    ],
);

$builder->create_build_script;
