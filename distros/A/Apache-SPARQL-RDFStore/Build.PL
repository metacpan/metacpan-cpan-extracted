use strict;
use Module::Build;

my $build = Module::Build->new(
				'module_name' => 'Apache::SPARQL::RDFStore',
				'dist_author' => 'Alberto Reggiori <alberto@asemantics.com>',	
			       	'dist_abstract' => 'A mod_perl handler which implements SPARQL bindings with RDFStore',
				'dist_version_from' => 'lib/Apache/SPARQL/RDFStore.pm',
				'license' => 'bsd', # see LICENSE file
				'requires' => {
					'mod_perl'          => '>= 1.29',
					'LWP::UserAgent'    => '>  1.00',
					'Apache::SPARQL'    => '>= 0.22',
					'RDFStore'          => '>= 0.51',
					'DBI'               => '>= 1.00',
					'XML::LibXML'       => '>= 1.58',
					'XML::LibXSLT'      => '>= 1.52',
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
