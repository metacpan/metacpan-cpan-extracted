use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'B::XPath',
    license             => 'perl',
    dist_author         => 'chromatic <chromatic@wgz.org>',
    dist_version_from   => 'lib/B/XPath.pm',
    build_requires => {
        'Test::More'   => 0,
		'Class::XPath' => 0,
		'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'B-XPath-*' ],
	sign                => 1,
	create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
