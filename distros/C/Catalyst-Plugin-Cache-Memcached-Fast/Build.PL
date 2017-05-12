use Module::Build;
my $builder = Module::Build->new(
	module_name			=> 'Catalyst::Plugin::Cache::Memcached::Fast',
	dist_abstract		=> 'Catalyst Plugin for Cache::Memcached::Fast',
	license				=> 'perl',
	dist_author			=> 'Vasiliy Voloshin <vasilus@cpan.org',
	dist_version_from	=> 'lib/Catalyst/Plugin/Cache/Memcached/Fast.pm',
	build_requires => {
        'Test::More'      => 0,
    },
	requires		=> {
		'Class::Data::Inheritable'	=> 0,
		'Cache::Memcached::Fast'    => 0,
		'Catalyst'                  => 0,
		'Test::More'				=> 0,
	},
	create_makefile_pl => 'traditional',
);
$builder->create_build_script();
