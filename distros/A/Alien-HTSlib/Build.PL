use strict;
use warnings;
use Config;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
    module_name        => 'Alien::HTSlib',
    dist_abstract      => 'Installation of HTSlib for Perl',
    license            => 'Apache_2_0',
    configure_requires => { 'Alien::Base::ModuleBuild' => 0, },
    requires           => {
        'perl'        => '5.8.1',
        'Alien::Base' => 0,
    },
    dist_author      => 'Rishi Nag <rishi@ebi.ac.uk>',
    alien_name       => 'htslib',
    alien_repository => {
        protocol       => 'http',
        host           => 'github.com',
        location       => '/samtools/htslib/archive/',
        exact_filename => 'master.zip',
        exact_version  => '1.3',
    },
    alien_build_commands   => ["make lib CC=$Config{cc} CFLAGS=\"-fPIC -g -Wall -O2\""],
    alien_install_commands => [
        'mkdir -p %s/lib',
        'cp libhts.a %s/lib',
        'mkdir -p %s/include',
        'cp *.h %s/include',
    ],
);
$builder->create_build_script;
