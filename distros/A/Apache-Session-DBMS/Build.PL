use strict;
use Module::Build;

my $build = Module::Build->new(
				'module_name' => 'Apache::Session::DBMS',
				'dist_author' => 'Alberto Reggiori <alberto@asemantics.com>',	
			       	'dist_abstract' => 'Session management via DBMS',
				'dist_version_from' => 'lib/Apache/Session/DBMS.pm',
				'license' => 'bsd', # see LICENSE file
				'requires' => {
					'Apache::Session'   => '>= 1.6',
					'DBMS'          => '>= 1.7'
					},
				'create_readme' => 1,
				'create_makefile_pl' => 'passthrough' );

$build->create_build_script();
