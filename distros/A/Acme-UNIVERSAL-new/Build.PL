use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::UNIVERSAL::new',
    license             => 'perl',
    dist_author         => 'chromatic <chromatic@wgz.org>',
    dist_version_from   => 'lib/Acme/UNIVERSAL/new.pm',
    build_requires =>
	{
        'Test::More'   => 0,
		'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'Acme-UNIVERSAL-new-*' ],
	create_makefile_pl  => 'traditional',
	sign                => 1,
);

$builder->create_build_script();
