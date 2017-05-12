use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name          => 'Carp::Parse',
	license              => 'GPL_3',
	dist_author          =>
	[
		'Guillaume Aubert <aubertg@cpan.org>',
		'Kate Kirby <kate@cpan.org>',
	],
	dist_version_from    => 'lib/Carp/Parse.pm',
	build_requires       =>
	{
		'File::Spec'      => 0,
		'Test::Deep'      => 0,
		'Test::Exception' => 0,
		'Test::More'      => 0,
	},
	requires             =>
	{
		'Carp'            => 0,
		'Data::Dump'      => 0,
		'perl'            => 5.010,
	},
	add_to_cleanup       =>
	[
		'Carp-Parse-*',
	],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	configure_requires   =>
	{
		'Module::Build'   => 0,
	},
	meta_merge           =>
	{
		resources         =>
		{
			repository => 'https://github.com/katekirby/Carp-Parse.git',
			homepage   => 'https://metacpan.org/release/Carp-Parse',
			bugtracker => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=carp-parse',
		},
	},
);

$builder->create_build_script();
