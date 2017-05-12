use strict;
use warnings;
use Module::Build;
use 5.010;

my $build = Module::Build->new(
	module_name	=> 'Convert::TBX::UTX',
	dist_abstract => 'Two way converter for TBX-Min and UTX Glossaries',
	license	=>	'perl',
	dist_version_from	=>	'lib/Convert/TBX/UTX.pm',
	script_files	=>	[ qw(bin/tbx2utx bin/utx2tbx) ],
	build_requires	=>	{
		"TBX::Min" => "0.05",
		"Exporter::Easy" => "0.16",
		"DateTime" => "1.06",
		"Path::Tiny" => "0.052",
		"Test::LongString" => "0.15",
		"Test::XML" => "0.08",
		"Test::Base" => "0.62"
	},
	create_makefile_pl => 'traditional',
);

$build->create_build_script();