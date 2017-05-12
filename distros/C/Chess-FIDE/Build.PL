use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Chess::FIDE',
	license             => 'perl',
	dist_author         => q{Roman M. Parparov <romm@cpan.org>},
	dist_version_from   => 'lib/Chess/FIDE.pm',
	configure_requires  => {
		'Module::Build' => 0.401,
	},
	build_requires => {
		'Module::Build' => 0.401,
		'Test::More' => 0,
	},
	requires            => {
		'IO::String'               => 1.08,
		'IO::File'                 => 1.14,
		'LWP::UserAgent'           => 6.05,
		'Archive::Zip'             => 1.32,
		'Archive::Zip::MemberRead' => 1.32,
		'Net::Ping'                => 2.39,
		'Sys::MemInfo'             => 0.91,
	},
	add_to_cleanup      => [ 'Chess-FIDE-*' ],
	create_makefile_pl => 'traditional',
	script_files        => {
		'scripts/fidesearch' => 'blib/scripts/fidesearch',
	},
);

$builder->create_build_script();
