use strict;
use Module::Build;

my $build = Module::Build->new(
				'module_name' => 'Apache::SPARQL',
				'dist_author' => 'Alberto Reggiori <alberto@asemantics.com>',	
			       	'dist_abstract' => 'A mod_perl handler base class for SPARQL query service using HTTP bindings',
				'dist_version_from' => 'lib/Apache/SPARQL.pm',
				'license' => 'bsd', # see LICENSE file
				'requires' => {
					'mod_perl'          => '>= 1.29',
					'LWP::UserAgent'    => '>  1.00',
					&apache_request()
					},
				'create_readme' => 1,
				'create_makefile_pl' => 'passthrough' );

$build->create_build_script();

sub apache_request {
	eval "require mod_perl";

	if ((! $@) && ($mod_perl::VERSION < 1.99)) {
		return ('Apache::Request' => '>= 1.3');
		};

	return ();
	};
