package Chandra::DevTools;

use strict;
use warnings;

use Chandra::Error;
use Chandra::Bind;

our $VERSION = '0.24';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
use Chandra;

# _xs_enable_setup is now handled by XSUBs in devtools.xs

1;

__END__

=head1 NAME

Chandra::DevTools - In-browser developer tools for Chandra applications

=head1 SYNOPSIS

	use Chandra::App;

	my $app = Chandra::App->new(title => 'My App', debug => 1);

	# Enable DevTools (auto-enabled via $app->devtools)
	$app->devtools->on_reload(sub {
	    $app->set_content(build_ui());
	    $app->refresh;
	});

	$app->set_content('<h1>Hello</h1>');
	$app->run;

	# Toggle DevTools with F12 or Ctrl+Shift+I in the browser

=head1 DESCRIPTION

Chandra::DevTools injects an in-browser developer panel into your
Chandra application.  The panel provides:

=over 4

=item B<Console> - Perl error log with stack traces and JS errors

=item B<Bindings> - List of Perl functions bound to JavaScript

=item B<Elements> - Live DOM tree inspector

=item B<Reload> - Trigger a reload callback to refresh content

=back

The panel is toggled with B<F12> or B<Ctrl+Shift+I>.

Errors captured by L<Chandra::Error> are automatically forwarded to the
console panel when DevTools is enabled.

=head1 METHODS

=head2 new(%args)

Create a new DevTools instance.  Usually accessed via C<< $app->devtools >>.

=head2 enable($app)

Activate DevTools: register helper bindings and error forwarding.

=head2 disable()

Deactivate DevTools and hide the panel.

=head2 inject($app)

Inject the DevTools JavaScript into the webview.

=head2 is_enabled()

Return true if DevTools is currently enabled.

=head2 on_reload($coderef)

Register a callback invoked when the Reload button is clicked.

=head2 toggle() / show() / hide()

Control panel visibility from Perl.

=head2 log($message) / warn($message)

Send informational or warning messages to the DevTools console.

=head2 js_code()

Return the raw DevTools JavaScript for manual injection.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Error>

=cut
