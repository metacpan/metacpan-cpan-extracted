# $Id: Build.PL,v 1.3 2004/11/16 04:33:33 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Apache::XPointer::RDQL',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Apache/XPointer/RDQL.pm',
			       license => 'perl',
			       requires => {
				   'Apache::XPointer' => '>= 1.1',
				   'RDFStore'         => '>= 0.50',
			       },
			       build_requires => {
				   'Test::Simple' => '>= 0.47',
			       },
			       create_readme => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
