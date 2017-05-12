use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name          => 'Business::SiteCatalyst',
	license              => 'artistic',
	dist_author          => q|Jennifer Pinkham <jpinkham@cpan.org>|,
	dist_version_from    => 'lib/Business/SiteCatalyst.pm',
	build_requires       =>
	{
		'Carp'                 => 0,
		'Data::Dumper'         => 0,
		'Data::Validate::Type' => "1.1.0",
		'DateTime'             => 0,
		'Digest::MD5'          => 0,
		'Digest::SHA1'         => 0,
		'HTTP::Request'        => 0,
		'JSON'                 => 0,
		'LWP::UserAgent'       => 0,
		'MIME::Base64'         => 0,
		'Test::More'           => 0.94,
		'Try::Tiny'            => 0,
	},
	requires             =>
	{
		'perl' => 5.006,
	},
	add_to_cleanup       => [ 'Business-SiteCatalyst-*' ],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	configure_requires   =>
	{
		'Module::Build'  => 0,
	},
	meta_merge           =>
	{
		resources        =>
		{
			repository  => 'https://github.com/jpinkham/business-sitecatalyst.git',
			homepage    => 'https://metacpan.org/release/Business-SiteCatalyst',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-SiteCatalyst',
		},
	},
);

$builder->create_build_script();
