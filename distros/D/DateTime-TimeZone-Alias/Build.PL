use Module::Build;
my $build = new Module::Build
	(
		module_name		=> 'DateTime::TimeZone::Alias',
		dist_version_from	=> 'lib/DateTime/TimeZone/Alias.pm',
		author			=> 'Joshua Hoblitt <jhoblitt@cpan.org>',
		license			=> 'perl',
		requires		=> {
			'DateTime'		=> 0,
			'DateTime::TimeZone::Catalog'	=> 0,
		},
	);
$build->create_build_script;
