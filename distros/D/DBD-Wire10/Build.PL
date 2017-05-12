use strict;
use warnings;
use Module::Build;

#
# This file contains information distilled from lib/DBD/Wire10.pm into
# a much more concise form by an automated tool.  From here, you can
# use Module::Build to create additional files containing secondary,
# tertiary and quaternary versions of the exact same information.
#
# First, create the Build script and _build cache:
#
# $ perl Build.PL
#
# (Notice that above, a script named "Build.PL" is used, while
#  below a different script named "Build" is used.)
#
# Then choose an action from this list:
#
# $ perl Build help
#
# Common actions are "help", "test" and "install".
#
# Notice that the install action does not take care of dependencies.
# Use the CPAN module installer for that.
#
# Other common actions are "manifest" for creating a dumb list of files
# and "distmeta" for duplicating the contents of the build cache into
# yet another mimeographic labor-phlebotomiser of a file format :-).
#

#
# Note:
# DBI is technically not a requirement, only DBI::PurePerl is.
#
# Rather than having the package manager take care of installing
# the best available version of DBI, various hacks and Makefile magic
# is used to force the XS version and the PurePerl version of DBI
# into the same package called DBI.  Therefore you will only see DBI
# in the list below, not DBI::PurePerl.

my $builder = Module::Build->new(
	module_name             => 'DBD::Wire10',
	license                 => 'perl',
	dist_version_from       => 'lib/DBD/Wire10.pm',
	build_requires => {
		'Test::More'             => 0.0,
	},
	requires => {
		'DBI'                    => 0.0,
		'Net::Wire10'            => 0.0,
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
