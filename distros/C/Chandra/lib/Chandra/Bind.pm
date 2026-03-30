package Chandra::Bind;

use strict;
use warnings;
use Cpanel::JSON::XS ();
use Chandra::Event;
use Chandra::Error;

our $VERSION = '0.06';

# Global registry of bound functions (per-app would be better, but matches XS callback limitation)
my %_registry;

# JSON encoder/decoder
my $json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

sub new {
	my ($class, %args) = @_;
	return bless {
		app => $args{app},
	}, $class;
}

# Register a Perl sub callable from JavaScript
sub bind {
	my ($self, $name, $sub) = @_;

	die "bind() requires a name" unless defined $name;
	die "bind() requires a coderef" unless ref $sub eq 'CODE';

	$_registry{$name} = $sub;
	return $self;
}

# Unregister a bound function
sub unbind {
	my ($self, $name) = @_;
	delete $_registry{$name};
	return $self;
}

# Check if a function is bound
sub is_bound {
	my ($self, $name) = @_;
	return exists $_registry{$name};
}

# List all bound function names
sub list {
	my ($self) = @_;
	return keys %_registry;
}

# Register a handler directly by ID (used by Chandra::Element)
sub register_handler {
	my ($class, $id, $sub) = @_;
	$_registry{$id} = $sub;
}

# Dispatch a call from JavaScript
# Called by XS callback with JSON string
sub dispatch {
	my ($self, $json_str) = @_;

	my $msg;
	eval {
		$msg = $json->decode($json_str);
	};
	if ($@) {
		warn "Chandra::Bind: Failed to parse JSON: $@";
		return { error => "Invalid JSON: $@" };
	}

	unless (ref $msg eq 'HASH') {
		return { type => 'raw', data => $json_str };
	}

	my $type = $msg->{type} // '';

	if ($type eq 'call') {
		return $self->_handle_call($msg);
	}
	elsif ($type eq 'event') {
		return $self->_handle_event($msg);
	}
	else {
		# Legacy: treat as raw string callback (backward compat)
		return { type => 'raw', data => $json_str };
	}
}

# Handle a function call from JS
sub _handle_call {
	my ($self, $msg) = @_;

	my $id = $msg->{id};
	my $method = $msg->{method};
	my $args = $msg->{args} // [];

	unless (exists $_registry{$method}) {
		return {
			id    => $id,
			error => "Unknown method: $method",
		};
	}

	my $result;
	my $error;

	eval {
		$result = $_registry{$method}->(@$args);
	};
	if ($@) {
		my $err = Chandra::Error->capture($@, context => "call($method)", skip => 0);
		$error = $err->{message};
	}

	return {
		id     => $id,
		result => $result,
		error  => $error,
	};
}

# Handle an event from JS (element onclick, etc.)
sub _handle_event {
	my ($self, $msg) = @_;

	my $handler_id = $msg->{handler};
	my $event_data = $msg->{event} // {};

	unless (exists $_registry{$handler_id}) {
		warn "Chandra::Bind: Unknown event handler: $handler_id";
		return { error => "Unknown handler: $handler_id" };
	}

	# Create Event object
	my $event = Chandra::Event->new($event_data);

	eval {
		$_registry{$handler_id}->($event, $self->{app});
	};
	if ($@) {
		my $err = Chandra::Error->capture($@, context => "event($handler_id)", skip => 0);
		warn Chandra::Error->format_text($err);
		return { error => $err->{message} };
	}

	return { ok => 1 };
}

# Encode result to JSON for sending back to JS
sub encode_result {
	my ($self, $result) = @_;
	return $json->encode($result);
}

# Generate JS code to resolve a promise
sub js_resolve {
	my ($self, $id, $result, $error) = @_;

	if (defined $error) {
		return sprintf(
			'window.chandra._resolve(%d, null, %s)',
			$id,
			$json->encode($error)
		);
	}
	else {
		return sprintf(
			'window.chandra._resolve(%d, %s, null)',
			$id,
			$json->encode($result)
		);
	}
}

1;

__END__

=head1 NAME

Chandra::Bind - JavaScript to Perl function binding

=head1 SYNOPSIS

	use Chandra::Bind;

	my $bind = Chandra::Bind->new(app => $app);

	# Register a Perl sub callable from JavaScript
	$bind->bind('greet', sub {
	    my ($name) = @_;
	    return "Hello, $name!";
	});

	# Check and list bindings
	if ($bind->is_bound('greet')) { ... }
	my @names = $bind->list;

	# Remove a binding
	$bind->unbind('greet');

	# In JavaScript:
	# const result = await window.chandra.invoke('greet', ['World']);

=head1 DESCRIPTION

Chandra::Bind manages the registry of Perl functions that can be called
from JavaScript. It handles JSON serialization, dispatching, and error
capture via L<Chandra::Error>.

=head1 CONSTRUCTOR

=head2 new

	my $bind = Chandra::Bind->new(app => $app);

Takes the L<Chandra::App> instance that owns this binding registry.

=head1 METHODS

=head2 bind

	$bind->bind($name, sub { ... });

Register a Perl subroutine as callable from JavaScript. C<$name> is the
function name used in C<window.chandra.invoke($name, \@args)>.

=head2 unbind

	$bind->unbind($name);

Remove a previously bound function.

=head2 is_bound

	my $bool = $bind->is_bound($name);

Returns true if a function with the given name is bound.

=head2 list

	my @names = $bind->list;

Returns the names of all bound functions.

=head2 register_handler

	Chandra::Bind->register_handler($id, sub { ... });

Class method. Register a handler by a specific ID. Used internally by
L<Chandra::Element> for event handler wiring.

=head2 dispatch

	$bind->dispatch($json_string);

Dispatch a call from JavaScript. The JSON string contains C<name>,
C<args>, and C<seq> fields. Called internally by the XS callback.
Errors are captured via L<Chandra::Error/capture>.

=head2 encode_result

	my $json = $bind->encode_result($result);

Encode a Perl value to JSON for returning to JavaScript.

=head2 js_resolve

	$bind->js_resolve($seq, $result, $error);

Generate and dispatch JavaScript to resolve or reject the promise
identified by C<$seq>.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Bridge>, L<Chandra::Element>, L<Chandra::Error>

=cut
