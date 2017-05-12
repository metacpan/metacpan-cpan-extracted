use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::ActsLike',
    license             => 'perl',
    dist_author         => 'chromatic <chromatic@wgz.org>',
    dist_version_from   => 'lib/Class/ActsLike.pm',
	requires            =>
	{
		'Class::Roles'  => '',
	},
    build_requires      =>
	{
        'Test::Simple'  => '0.60',
    },
    add_to_cleanup      => [ 'Class-ActsLike-*' ],
	create_makefile_pl  => 'traditional',
	sign                => 1,
);

$builder->create_build_script();
