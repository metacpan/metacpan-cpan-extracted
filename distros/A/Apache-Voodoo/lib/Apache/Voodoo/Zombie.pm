=pod #####################################################################################

=head1 NAME

Apache::Voodoo::Zombie - Internal module used by Voodoo when a end user module doesn't compile.

=head1 SYNOPSIS

This module is used by Apache::Voodoo::Application as a stand in for a module that didn't compile
when either devel_mode or debug is 1 in the application's voodoo.conf.  Any calls to this module simply
throw an exception describing the describing the compilation error.
This is a development tool...you shouldn't have any Zombies in your production environment :)

=cut ################################################################################
package Apache::Voodoo::Zombie;

$VERSION = "3.0200";

use strict;
use warnings;

use Apache::Voodoo::Exception;

sub new {
	my $class  = shift;
	my $module = shift;
	my $error  = shift;

	my $self = {
		'module' => $module,
		'error'  => $error
	};

	bless ($self,$class);
	return $self;
}

#
# Autoload is used to catch whatever method was supposed to be invoked
# in the dead module.
#
sub AUTOLOAD {
	next unless ref($_[0]);

	my $self = shift;
	my $p    = shift;

	our $AUTOLOAD;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->error($self->{'module'},$self->{'error'});
	}

	Apache::Voodoo::Exception::Compilation->throw(
		'module' => $self->{'module'},
		'error'  => $self->{'error'}
	);
}

# keeps autoloader from making one
sub DESTROY {}

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
