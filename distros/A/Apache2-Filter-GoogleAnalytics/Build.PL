use strict;
use warnings;

use Module::Build;

my $build = new Module::Build (
	module_name	=> 'Apache2::Filter::GoogleAnalytics',
	license		=> 'perl',
	dist_author	=> 'Lubomir Rintel <lkundrak@v3.sk>',
	dist_version_from => 'lib/Apache2/Filter/GoogleAnalytics.pm',
	create_readme	=> 1,
	requires	=> {
		'HTML::Parser'		=> 0,
		'Apache2::Filter'	=> 0,
		'Apache2::Module'	=> 0,
		'Apache2::RequestRec'	=> 0,
		'APR::Table'		=> 0,
		'Apache2::Const'	=> 0,
	}
);

$build->create_build_script;
