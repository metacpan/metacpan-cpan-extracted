use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::MorningMusume::ShinMember',
    license             => 'perl',
    dist_author         => 'Jonathan Rockway <jrockway@cpan.org>',
    dist_version_from   => 'lib/Acme/MorningMusume/ShinMember.pm',
    requires   => {
 	'Acme::MorningMusume' => 0,
 	'Acme::BloodType' => 0,

    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Acme-MorningMusume-ShinMember-*' ],
    install_script => ['bin/genmusume'],
);

$builder->create_build_script();
