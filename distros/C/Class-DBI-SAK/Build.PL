# $Id: Build.PL,v 1.1 2003/09/23 00:10:33 cwest Exp $
use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Class::DBI::SAK',
	license     => 'perl',
	requires    => {
		'Class::DBI' => 0,
	},
	recommends  => {
		'Class::DBI::AbstractSearch' => 0,
		'Class::DBI::Pager'          => 0,
	},
	build_requires => {
		'Class::DBI::AbstractSearch' => 0,
		'Class::DBI::Pager'          => 0,
		'mixin'                      => 0,
		'Test::More'                 => 0,
		'Module::Build'              => 0,
	},
)->create_build_script;
