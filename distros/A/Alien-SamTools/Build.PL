use strict;
use warnings;
use Config;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
    module_name        => 'Alien::SamTools',
    dist_abstract      => 'Easy installation of SamTools',
    license            => 'perl',
    configure_requires => { 'Alien::Base' => 0, },
    requires           => {
        'perl'        => '5.8.1',
        'Alien::Base' => 0,
    },
    dist_author      => 'George Hartzell <hartzell@cpan.org>',
    alien_name       => 'samtools',
    # if you update this, update the docs in lib/Alien/SamTools.pm!
    alien_repository => {
        protocol       => 'http',
        host           => 'github.com',
        location       => '/samtools/samtools/archive/',
        exact_filename => '0.1.19.tar.gz',
        exact_version  => '0.1.19',
    },
    alien_build_commands   => ["make lib CC=$Config{cc} CFLAGS=\"-fPIC -g -Wall -O2\""],
    alien_install_commands => [
        'mkdir -p %s/lib',
        'cp libbam.a %s/lib',
        'mkdir -p %s/include',
        'cp *.h %s/include',
    ],
);
$builder->create_build_script;
