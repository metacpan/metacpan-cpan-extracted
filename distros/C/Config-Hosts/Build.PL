use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name	        => 'Config::Hosts',
	license             => 'perl',
	dist_author         => q{Roman M. Parparov <roman@parparov.com>},
	dist_version_from   => 'lib/Config/Hosts.pm',
	build_requires      => {
		'Test::More' => 0,
	},
	requires            => {
		'Regexp::IPv6' => '0.03',
	},
	add_to_cleanup      => [ 'Config-Hosts-*' ],
	create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
