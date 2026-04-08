package Chandra::Bind;

use strict;
use warnings;
use Cpanel::JSON::XS ();

our $VERSION = '0.17';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

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
