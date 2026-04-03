package Chandra::Bridge;

use strict;
use warnings;

our $VERSION = '0.10';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

1;

__END__

=head1 NAME

Chandra::Bridge - JavaScript bridge code for Perl communication

=head1 SYNOPSIS

	use Chandra::Bridge;

	# Get the JS code to inject
	my $js = Chandra::Bridge->js_code;

	# Get the JS code escaped for eval
	my $escaped = Chandra::Bridge->js_code_escaped;

=head1 DESCRIPTION

This module contains the JavaScript bridge code that enables
communication between JavaScript and Perl via C<window.chandra>.

You normally do not use this module directly; L<Chandra::App> injects
the bridge automatically.

=head2 JavaScript API

After injection, the following is available in JavaScript:

	// Call a Perl function (returns Promise)
	const result = await window.chandra.invoke('method_name', [arg1, arg2]);

	// Shorthand
	const result = await window.chandra.call('method_name', arg1, arg2);

=head1 METHODS

=head2 js_code

	my $js = Chandra::Bridge->js_code;

Class method. Returns the raw JavaScript source for the bridge.

=head2 js_code_escaped

	my $js = Chandra::Bridge->js_code_escaped;

Class method. Returns the bridge code wrapped for injection via
C<eval_js> (newlines and quotes escaped).

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Bind>

=cut
