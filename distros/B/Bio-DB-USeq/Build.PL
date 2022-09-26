#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	build_class       => 'Module::Build',
	module_name       => 'Bio::DB::USeq',
	license           => 'perl',
	dist_version_from => 'lib/Bio/DB/USeq.pm',
	dist_author       => 'Timothy Parnell <parnell.tj@gmail.com>',
	meta_merge        => {
		resources     => {
			repository     => 'https://github.com/tjparnell/Bio-DB-USeq'
		}
	},
	configure_requires => {
		'Module::Build'       => 0,
	},
	requires          => {
		'perl'                => '5.10.0',
		'Bio::Root::Version'  => '1.0069001',
		'Archive::Zip'        => '1.67',
		'Set::IntervalTree'   => '0.10',
	},
	script_files      => [ 'scripts/USeqInfo.pl' ],
);

$build->create_build_script;
exit 0;
