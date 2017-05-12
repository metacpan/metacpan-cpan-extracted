package Apache::Voodoo::Loader::Dynamic;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Loader");

sub new {
	my $class = shift;

	my $self = {};
	bless $self,$class;

	$self->{'module'} = shift;

	$self->{'bootstrapping'} = 1;
	$self->refresh;
	$self->{'bootstrapping'} = 0;

	$self->{'parents'} = {};
	foreach (eval '@{'.$self->{'module'}.'::ISA}') {
		$self->{'parents'}->{$_} = $self->get_mtime($_);
	}

	return $self;
}

sub init {
	my $self = shift;

	$self->{'config'} = \@_;
	$self->{'object'}->init(@_);
}

sub get_mtime {
	my $self = shift;
	my $file = shift || $self->{'module'};

	$file =~ s/::/\//go;
	$file .= ".pm";

	return 0 unless defined($INC{$file});

	my $mtime = (stat($INC{$file}))[9];

	return $mtime;
}

sub refresh {
	my $self = shift;

	$self->{'object'} = $self->load_module;
	$self->{'mtime'}  = $self->get_mtime;

	# zap our created closures.
	foreach my $method (keys %{$self->{'provides'}}) {
		# a little help from the Cookbook 10.14
		no strict 'refs';
		no warnings 'redefine';
		*$method = undef;
	}
	$self->{'provides'} = {};
}

#
# Override the built in 'can' to allow:
#   a) trigger dynamically reloading the module as needed
#   b) dynamically create closures to link Apache::Voodoo::Handler with the controllers
#
sub can {
	my $self   = shift;
	my $method = shift;
	my $nosub  = shift;

	# find out if this thing has changed
	if ($self->{'mtime'} != $self->get_mtime) {
		$self->refresh;
		$self->{'object'}->init(@{$self->{'config'}});
	}

	if (defined $self->{'provides'}->{$method}) {
		return 1;
	}
	elsif ($self->{'object'}->isa("Apache::Voodoo::Zombie") || $self->{'object'}->can($method)) {
		# Either we have a dead module and we map whatever was requested or
		# we have a live one and has the requested method.

		# cache the existance of this method
		$self->{'provides'}->{$method} = 1;

		# If we used the autoloader to get here, then we want to keep using
		# it. Bypass the creation of the closure.
		unless ($nosub) {
			# create a closeure for this method (a little help from the Cookbook 10.14)
			no strict 'refs';
			no warnings 'redefine';
			*$method = sub { my $self = shift; return $self->_handle($method,@_); };
		}
		return 1;
	}

	return 0;
}

#
# In scnearios where the caller doesn't know that can has been overloaded, we'll use
# autoload to catch it and call our overloaded can.  We unfortunately end up with two
# different ways to do a very similar task because the constraints are slightly different.
# We want the calls from the A::V::Handler to the controllers to be aware of what methods
# actually exist so it can either call them or not.  The controllers talking to the models
# shouldn't have to do anything special or even be aware that they're talking to this
# proxy object, thus the need for a autoload variation.
#
sub AUTOLOAD {
	next unless ref($_[0]);

	our $AUTOLOAD;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://;

	my $self = shift;

	if ($self->can($method,'1')) {
		return $self->_handle($method,@_);
	}

	# we don't handle this one
	next;
}

# now we need a stub for destroy to keep autoloader happy.
sub DESTROY { }

sub _handle {
	my $self = shift;
	my $method = shift;
	my @params = @_;

	# check parent modules for change
	foreach my $module (eval '@{'.$self->{'module'}.'::ISA}') {
		my $t = $self->get_mtime($module);
		if ($self->{'parents'}->{$module} != $t) {
			$self->{'parents'}->{$module} = $t;

			my $file = $module;
			$file =~ s/::/\//go;
			$file .= ".pm";

			no warnings 'redefine';
			delete $INC{$file};
			eval {
				no warnings 'redefine';
				require $file;
			};
			if ($@) {
				my $error= "There was an error loading one of the base classes for this page ($_):\n\n$@\n";

				my $link = $self->{'module'};

				$link =~ s/::/\//g;
				unless ($method eq "handle") {
					$link =~ s/([^\/]+)$/$method."_".$1/e;
				}

				# FIXME replace with a instance of Apache::Voodoo::Zombie
				$self->debug("ZOMBIE: $self->{'module'} $method");
				return $self->display_error($error,"/$link");
			}
		}
	}

	return $self->{'object'}->$method(@params);
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
