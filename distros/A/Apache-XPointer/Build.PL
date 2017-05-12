# $Id: Build.PL,v 1.2 2004/11/13 23:30:02 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Apache::XPointer',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Apache/XPointer.pm',
			       license => 'perl',
			       requires => {
				   'perl'                      => '>= 5.6.0',
				   'mod_perl'                  => '>= 1.29',
				   'XML::LibXML'               => '>= 1.58',
				   'XML::LibXML::XPathContext' => '>= 0.06',
				   &apache_request(),
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();

sub apache_request {
    eval "require mod_perl";

    if ((! $@) && ($mod_perl::VERSION < 1.99)) {
	return ('Apache::Request' => '>= 1.3');
    }

    return ();
}
