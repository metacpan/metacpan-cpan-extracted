package Apache::Action;

use strict;
use vars qw($VERSION @ISA %ACTIONS);
use Carp;
use Exporter;
use Data::Dumper;
use Apache::Constants qw(:response);

$VERSION = 0.02;
@ISA = qw(Exporter);

# Class methods

sub register {
	my $self = shift;
	my $app = shift;
	my $module = shift;
	my $actions = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	my ($package) = caller;

	foreach (keys %$actions) {
		my $val = $actions->{$_};
		my $subref;

		if (ref($val) eq 'CODE') {
			# val is a coderef
			$subref = $val;
		}
		elsif (ref($val)) {
			die "Cannot use reference to " . ref($val) .
					" as an action routine.";
		}
		else {
			no strict qw(refs);
			my $subref = ($val =~ /::/)
					? \&{"$val"}
					: \&{"$package\::$val"};
			die "No such subroutine " . $val
							unless $subref;
		}

		$ACTIONS{$app}->{$module}->{$_} = $subref;
	}
}

# Instance methods

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	die "No Request in Apache::Action" unless $self->{Request};
	die "No Session in Apache::Action" unless $self->{Session};
	die "No State in Apache::Action" unless $self->{State};
	$self->{Errors} = [ ];
	return bless $self, $class;
}

sub run {
	my ($self) = @_;

	my $httparg = $self->param('action');
	$self->param('action', undef);
	return OK unless length($httparg);

	my ($app, $module, $action) = split("/", $httparg);

	return OK unless
				length($app) &&
				length($module) &&
				length($action);

	unless (exists $ACTIONS{$app}) {
		$self->error("No such application $app.");
		$self->{State}->error($self->errors);
		return NOT_FOUND;
	}

	unless (exists $ACTIONS{$app}->{$module}) {
		$self->error("No such module $module in application $app.");
		$self->{State}->error($self->errors);
		return NOT_FOUND;
	}

	unless (exists $ACTIONS{$app}->{$module}->{$action}) {
		$self->error("No such action $action in module $module " .
						"of application $app.");
		$self->{State}->error($self->errors);
		return NOT_FOUND;
	}

	print STDERR "Running $module -> $action\n";
	my $status = $ACTIONS{$app}->{$module}->{$action}->($self);

	$self->{State}->error($self->errors);

	return $status;
}

sub error {
	my $self = shift;
	push(@{ $self->{Errors} }, @_);
}

sub errors {
	return @{ $_[0]->{Errors} };
}

sub param {
	my $self = shift;
	my $key = shift;

	my $t = $self->{Request}->parms;    # Apache::Table

	if ($#_ >= 0) {
		my $value = shift;
		if (!defined($value)) {
			# print STDERR "Module: Modified parameter $key (UNSET)\n";
			confess "Invalid key " . Dumper($key) if ref $key;
			$t->unset($key);
		}
		elsif (ref($value) eq 'ARRAY') {
			# print STDERR "Module: Modified parameter $key => $value\n";
			# We convert list refs into separate table entries.
			$t->unset($key);
			foreach my $el (@$value) {
				$t->add($key, $el);
			}
		}
		else {
			# print STDERR "Module: Modified parameter $key => $value\n";
			$t->set($key, $value);
		}
	}

	# scalar/array context is passed on to this request.
	return $self->{Request}->param($key);
}

sub session {
	my $self = shift;
	my $key = shift;
	if ($#_ >= 0) {
		my $value = shift;
		$self->{Session}->{$key} = $value;
	}
	return $self->{Session}->{$key};
}

sub state {
	my $self = shift;
	return $self->{State};
}

sub params {
	my $self = shift;
	# Tied hash to Apache::Table
	my $parms = $self->{Request}->parms;
	# Make a copy
	return { %{ $parms } };
}

sub upload {
	my $self = shift;
	# scalar/array context is passed on to this request.
	return $self->{Request}->upload(@_);
}

=head1 NAME

Apache::Action - A method dispatch mechanism for Apache

=head1 SYNOPSIS

	# An Apache handler to manage the cycle.
	package My::Apache::Handler;
	my $ah = new HTML::Mason::ApacheHandler...);
	sub handler {
		my ($r) = @_;
		...
		tie %SESSION, 'Apache::Session::....';
		my $state = new Apache::Action::State(	# Or custom state class
			Request	=> $r,
			Session	=> \%SESSION,
				);
		my $action = new Apache::Action(
			Request	=> $r,
			Session	=> \%SESSION,
			State	=> $state,
				);
		my $status = eval { $action->run; };
		if ($@) { $state->error($@); $status = SERVER_ERROR; }
		unless ($status == OK) {
			my $subreq = $r->lookup_uri('/error.html');
			$r->filename($subreq->filename);
		}
		return $ah->handle_request($r);
	}

	# A set of action handlers
	package My::Apache::Actions;
	use base 'Apache::Action';
	__PACKAGE__->register('AppName', 'ObjectName',
		action0	=> \&handler0,
		action1	=> \&handler1,
		...
			);
	sub handler0 {
		my ($self) = @_;
		# my $user = $self->state->user;	# If user defined.
	}

=head1 DESCRIPTION

This module reads values out of the HTTP submission and dispatches
to code as appropriate. The architecture requires four elements:

=over 4

=item The apache request

This is normally a singleton instance of Apache::Request.

=item The persistent session

This is usually an Apache::Session, but anything which provides a
hashref will do. The session stores the persistent data, and may be
serialised by any method desired.

=item A request state

This is usually a subclass of Apache::Action::State and stores
nonserialisable and per-request data.

=item An action dispatcher.

This is an Apache::Action instance.

=back

It is normal to write a class which inherits Apache::Action::State,
which generates and caches nonserialisable or non-normalised  data
on demand. Things like user id may be stored in the session, and
the state may then provide a 'user' method which reads the user-id
from the session and retrieves the user from the database, caching
the object for the duration of the request. See eg/State.pm in this
distribution for an example.

Loaded modules may register actions with Apache::Action using the
'register' call, as described above. When an Apache::Action is 'run',
it looks for the field 'action' in the HTTP request parameters. This
field is of the form "application/module/action". It will then call the
appropriate subref, passing itself as the one and only parameter.

When using this module with HTML::Mason, it is normal to exoprt the
state and the session into the HTML::Mason::Commands namespace so
that they can be accessed by pages.

=head1 METHODS

=over 4

=item Apache::Action->register($app, $module, $action)

Register a new action with Apache::Action. This is a class method and is
designed to be called from the top level of any loaded Perl module. See
eg/Feedback.pm for an example.

=item Apache::Action->new(...)

Construct a new Action object. This reqires three parameters: Request,
Session and State. The Request is an Apache::Request instance. The
Session is usually an Apache::Session instance but may be any session
hash. The State is an instance of Apache::Action::State;

=item $action->run()

Search the HTTP arguments in the Request, and run an action, if
appropriate.

=item $action->param($name)

Return the HTTP parameter named.

=item $action->params($name)

Return a hashref of all HTTP parameters, copying the data.

=item $action->upload

Return an Apache::Upload object as named.

=item $action->session($name)

Return data from the session hash, as named.

=item $action->session($name, $value)

Store data in the session hash, as named.

=item $action->error($error)

Record that an error happened during this execution. The action object
will add the errors to the state object at the end of the run. It is
the responsibility of the Apache handler writer to check whether any
errors were recorded in the action object before continuing. This method
merely provides a log.

=item $action->errors()

Return a list of errors recorded in this execution.

=back

=head1 BUGS

Mostly documentation. This code has been pulled out of a running
system and patched up for CPAN, so patches welcome if it doesn't run
as smoothly as expected outside of that system.

This module is quite hard to test outside Apache.

=head1 SUPPORT

Mail the author at <cpan@anarres.org>

=head1 AUTHOR

	Shevek
	CPAN ID: SHEVEK
	cpan@anarres.org
	http://www.anarres.org/projects/

=head1 COPYRIGHT

Copyright (c) 2004 Shevek. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Apache::Action::State
Apache::Session
HTML::Mason

=cut

1;
__END__
