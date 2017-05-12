package Apache::Voodoo::Application;

$VERSION = "3.0200";

use strict;
use warnings;

use Apache::Voodoo::Constants;
use Apache::Voodoo::Application::ConfigParser;

use Apache::Voodoo::Session;
use Apache::Voodoo::Debug;

use Data::Dumper;

sub new {
	my $class = shift;
	my $self = {};

	bless $self, $class;

#	$self->{'debug'} = 1;

	$self->{'id'}        = shift;
	$self->{'constants'} = shift || Apache::Voodoo::Constants->new();

	die "ID is a required parameter." unless (defined($self->{'id'}));

	$self->{'parser'} = Apache::Voodoo::Application::ConfigParser->new($self->{'id'},$self->{'constants'});
	$self->refresh(1);

	return $self;
}

sub config {
	return $_[0]->{'parser'}->config();
}

sub databases {
	return $_[0]->{'parser'}->databases();
}

sub bootstrapped {
	my $self = shift;

	$self->{debug_handler}->bootstrapped();
}

sub refresh {
	my $self    = shift;
	my $initial = shift;

	# If this is the initial load, or the config file has changed continue.
	unless ($initial || $self->{'parser'}->changed()) {
		return;
	}

	my $config = $self->{'parser'};

	my %old_m = %{$config->models()};
	my %old_v = %{$config->views()};
	my %old_c = %{$config->controllers()};
	my %old_i = %{$config->includes()};

	my $old_ns = $config->old_ns();

	$config->parse();

	$self->_reload_modules('m',\%old_m,$config->models());
	$self->_reload_modules('v',\%old_v,$config->views());

	if (defined($old_ns) && $old_ns != $config->old_ns()) {
		# They've swapped from the old style name for controller to the new syle
		# (or vice versa).  Drop all the old controllers.

		$self->_debug("**Controller namespace has changed**");
		foreach (keys %{$self->{'controllers'}}) {
			$self->_debug("Removing old module: $_");
			delete $self->{'controllers'}->{$_};
		}
		%old_c = ();
		%old_i = ();
	}

	# load the new includes
	$self->_reload_modules('c',\%old_i,$config->includes());

	foreach (sort keys %{$config->controllers()}) {
		unless (exists($old_c{$_})) {
			# new module
			$self->_debug("Adding new module: $_");
			$self->_prep_page_module($_);
		}
		delete $old_c{$_};
	}

	foreach (keys %old_c) {
		$self->_debug("Removing old module: $_");
		delete $self->{'controllers'}->{$_};
	}

	# If they didn't define their own HTML view, then we'll use our own;
	# this is a web server after all :)
	unless (defined($self->{'views'}->{'HTML'})) {
		require Apache::Voodoo::View::HTML;
		$self->{'views'}->{'HTML'} = Apache::Voodoo::View::HTML->new();
	}

	# Same idea for JSON.  What website these days doesn't use even
	# a little AJAX?
	unless (defined($self->{'views'}->{'JSON'})) {
		require Apache::Voodoo::View::JSON;
		$self->{'views'}->{'JSON'} = Apache::Voodoo::View::JSON->new();
	}

	# models get the config and every model except themselves
	# to prevent accidental circular references
	foreach my $key (keys %{$self->{'models'}}) {
		my %m = map { $_ => $self->{models}->{$_} }
		        grep { $_ ne $key }
		        keys %{$self->{'models'}};

		eval {
			$self->{models}->{$key}->init($config->config(),\%m);
		};
		if ($@) {
			warn "$@\n";
			$self->{'errors'}++;
		}
	}

	# views get just the config
	foreach (values %{$self->{'views'}}) {
		eval {
			$_->init($config->config());
		};
		if ($@) {
			warn "$@\n";
			$self->{'errors'}++;
		}
	}

	# controllers get the config and all the models
	foreach (values %{$self->{'controllers'}}) {
		eval {
			$_->init($config->config(),$self->{'models'});
		};
		if ($@) {
			warn "$@\n";
			$self->{'errors'}++;
		}
	}


	eval {
		$self->{'session_handler'} = Apache::Voodoo::Session->new($config->config());
	};
	if ($@) {
		warn "$@\n";
		$self->{'errors'}++;
	}

	eval {
		$self->{'debug_handler'} = Apache::Voodoo::Debug->new($config->config());
	};
	if ($@) {
		warn "$@\n";
		$self->{'errors'}++;
	}

}

sub map_uri {
	my $self = shift;
	my $uri  = shift;

	if (defined($self->{'controllers'}->{$uri})) {
		return [$uri,"handle"];
	}
	else {
		no warnings 'uninitialized';
		my $p='';
		my $m='';
		my $o='';
		($p,$m,$o) = ($uri =~ /^(.*?)([a-z]+)_(\w+)$/);
		return ["$p$o",$m];
	}
}

sub resolve_conf_section {
	my $self = shift;
	my $uri  = shift;

	my $template_conf = $self->{'parser'}->template_conf();

	if (exists($template_conf->{$uri})) {
		# one specific to this page
		return $template_conf->{$uri};
	}

	foreach (sort { length($b) <=> length($a) } keys %{$template_conf}) {
		if ($uri =~ /^$_$/) {
			# match by uri regexp
			return $template_conf->{$_};
		}
	}

	# not one, return the default
	return $template_conf->{'default'};
}

sub _reload_modules {
	my $self = shift;
	my $ns   = shift;
	my $old  = shift;
	my $new  = shift;

	# check the new list of modules against the old list
	foreach (sort keys %{$new}) {
		unless (exists($old->{$_})) {
			# new module (wasn't in the old list).
			$self->_debug("Adding new $ns module: $_");
			$self->_prep_module($ns,$_);
		}

		# still a valid module, so remove it from this list.
		delete $old->{$_};
	}

	# whatever is left in old are ones that weren't in the new list.
	foreach (keys %{$old}) {
		$self->_debug("Removing old module: $_");
		$_ =~ s/::/\//g;
		delete $self->{'controllers'}->{$_};
	}
}

sub _prep_module {
	my $self   = shift;
	my $ns     = shift;
	my $module = shift;

	my $obj = $self->_load_module($ns,$module);

	$ns = ($ns eq "m")?"models":
	      ($ns eq "v")?"views":"controllers";

	$self->{$ns}->{$module} = $obj;
}

sub _prep_page_module {
	my $self   = shift;
	my $module = shift;

	my $obj = $self->_load_module('c',$module);
	$module =~ s/::/\//g;

	$self->{'controllers'}->{$module} = $obj;
}

sub _load_module {
	my $self   = shift;
	my $ns     = shift;
	my $module = shift;


	unless ($ns eq "c" and $self->{'parser'}->old_ns()) {
		$module = uc($ns)."::".$module;
	}

	$module = $self->{'parser'}->config()->{'base_package'}."::".$module;

	my $obj;
	if ($self->{'parser'}->config()->{'dynamic_loading'}) {
		require Apache::Voodoo::Loader::Dynamic;

		$obj = Apache::Voodoo::Loader::Dynamic->new($module);
	}
	else {
		require Apache::Voodoo::Loader::Static;

		$obj = Apache::Voodoo::Loader::Static->new($module);
		if (ref($obj) eq "Apache::Voodoo::Zombie") {
			# doh! the module went boom
			$self->{'errors'}++;
		}
	}

	return $obj;
}

sub _debug {
	my $self = shift;

	return unless $self->{'debug'};

	if (ref($_[0])) {
		warn Dumper(@_);
	}
	else {
		warn join("\n",@_),"\n";
	}
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
