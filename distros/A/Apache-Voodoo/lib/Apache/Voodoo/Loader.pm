################################################################################
#
# Apache::Voodoo::Loader
#
# Base class for each of the module loading mechanisms.  Look at Loader::Static
# and Loader::Dynamic
#
################################################################################
package Apache::Voodoo::Loader;

$VERSION = "3.0200";

use strict;
use warnings;

sub load_module {
	my $self    = shift;
	my $module  = shift || $self->{'module'};

	my $file = $module;
	$file =~ s/::/\//go;
	$file .= ".pm";

	# HERE BE THE BLACK MAGIC
	# perl stores the names of the loaded modules in here.
	# so, if you require the same module twice (or you change it on disk later)
	# perl consults this hash and doesn't reload it.
	# delete the entry, and perl will re-require the module from scratch
	#
	# We don't want to do this when the server is starting for the first time.  If
	# we're running multiple instances of the same application, then we're just
	# wasting time recompiling the same modules over and over, and "warnings" will
	# sometimes (uselessly) yell about modules being redefined.
	unless ($self->{'bootstrapping'}) {
		no warnings 'redefine';
		delete $INC{$file};
	}

	my $obj;
	eval {
		no warnings 'redefine';
		local $SIG{__DIE__};
		require $file;
		$obj = $module->new();
	};
	if ($@) {
		my $error = "$@";
		$error =~ s/Compilation failed in require at .*Apache\/Voodoo\/Loader.pm line.*//;

		$module =~ s/^[^:]+:://;

		require Apache::Voodoo::Zombie;
		$obj = Apache::Voodoo::Zombie->new($module,$error);
	}

	return $obj;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
