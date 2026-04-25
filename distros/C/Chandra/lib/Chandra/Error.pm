package Chandra::Error;

use strict;
use warnings;

our $VERSION = '0.24';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
use Chandra;

1;

__END__

=head1 NAME

Chandra::Error - Error handling with stack traces for Chandra

=head1 SYNOPSIS

	use Chandra::Error;

	# Register an error handler
	Chandra::Error->on_error(sub {
	    my ($err) = @_;
	    warn Chandra::Error->format_text($err);
	});

	# Capture an error (typically used internally)
	eval { die "something broke" };
	my $err = Chandra::Error->capture($@, context => 'MyModule');

	# Format for display
	my $text = Chandra::Error->format_text($err);
	my $js   = Chandra::Error->format_js_console($err);

=head1 DESCRIPTION

Chandra::Error provides centralised error handling with stack traces
for the Chandra framework.  When an error is captured it is recorded
with its originating context and a stack trace, then all registered
handlers are notified.

Chandra::Bind uses this module automatically so that callback errors
are surfaced to DevTools and any custom on_error handlers.

=head1 CLASS METHODS

=head2 on_error($coderef)

Register a callback invoked whenever C<capture()> records an error.
The callback receives a single hashref argument.

=head2 clear_handlers()

Remove all registered error handlers.

=head2 handlers()

Return an arrayref of currently registered handlers.

=head2 capture($error, %opts)

Capture an error.  Options:

=over 4

=item context - descriptive label, e.g. C<'call(greet)'>

=item skip - stack frames to skip (default 2)

=back

Returns a hashref: C<{ message, context, trace, time }>.

=head2 format_text($err)

Render a captured error as a multi-line string with stack trace.

=head2 format_js_console($err)

Return a JavaScript C<console.error(...)> statement for the error.

=head2 stack_trace($skip)

Build a stack trace starting C<$skip> frames above the caller.
Returns an arrayref of C<{ package, file, line, sub }> hashrefs.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Bind>, L<Chandra::DevTools>

=cut
