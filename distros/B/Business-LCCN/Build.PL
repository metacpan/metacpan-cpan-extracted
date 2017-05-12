use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Business::LCCN',
    license             => 'perl',
    dist_author         => 'Anirvan Chatterjee <anirvan@cpan.org>',
    dist_version_from   => 'lib/Business/LCCN.pm',
    requires => {
	'perl' => '5.6.1',
	'Carp' => 0,
	'Moose' => 0.34,
	'Moose::Util::TypeConstraints' => 0,
	'Scalar::Util' => 1.23,
        'Test::More' => 0,
	'URI' => 1.19,
    },
    add_to_cleanup      => [ 'Business-LCCN-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
