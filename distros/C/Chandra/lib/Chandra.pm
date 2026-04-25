package Chandra;

use strict;
use warnings;

our $VERSION = '0.24';

require XSLoader;
XSLoader::load('Chandra', $VERSION);

use Chandra::Bind;
use Chandra::Bridge;

1;

__END__

=head1 NAME

Chandra - Perl bindings to webview-c for creating cross-platform GUIs

=head1 SYNOPSIS

	use Chandra;

	# Simple one-liner
	Chandra->new(
	    title  => 'My App',
	    url    => 'https://example.com',
	    width  => 800,
	    height => 600,
	)->run;

	# Advanced usage with event loop control
	my $app = Chandra->new(
	    title    => 'My App',
	    url      => 'data:text/html,<h1>Hello from Perl!</h1>',
	    debug    => 1,
	    callback => sub {
	        my ($arg) = @_;
	        print "JS called: $arg\n";
	    },
	);

	$app->init;

	while ($app->loop(1) == 0) {
	    # Event loop
	}

	$app->exit;

=head1 DESCRIPTION

This module provides Perl bindings to the webview-c library, allowing you to
create cross-platform GUI applications using web technologies (HTML, CSS, JS).

Supported platforms:

=over 4

=item * macOS (WebKit/WKWebView)

=item * Linux (WebKitGTK)

=item * Windows (Edge/WebView2 with MSHTML fallback)

=back

=head2 Windows WebView2 Requirements

On Windows, Chandra uses the modern Edge/WebView2 (Chromium-based) browser
component when available, with automatic fallback to the legacy MSHTML
(IE11-era) component.

For best results, ensure the WebView2 Runtime is installed:

=over 4

=item * Windows 10 1803+ and Windows 11 include WebView2 Runtime by default

=item * Or download from L<https://developer.microsoft.com/en-us/microsoft-edge/webview2/>

=item * WebView2Loader.dll must be in PATH or application directory

=back

If WebView2 is not available, Chandra falls back to MSHTML (Internet Explorer
rendering engine), which has limited modern web feature support.

See:

=over 4

=item * examples/bind_example.pl — JavaScript to Perl function binding

=item * examples/counter_app.pl — counter app with bidirectional communication

=back

For the high-level application wrapper see L<Chandra::App>.

=head1 METHODS

=head2 new(%args)

Create a new Chandra webview instance.

    my $wv = Chandra->new(
        title    => 'My App',
        url      => 'data:text/html,<h1>Hello</h1>',
        width    => 800,
        height   => 600,
        resizable => 1,
        debug    => 0,
        callback => sub { my ($arg) = @_; ... },
    );

Options:

=over 4

=item title

Window title (default: C<'Chandra'>).

=item url

Initial URL or data URI (default: C<'about:blank'>).

=item width

Window width in pixels (default: C<800>).

=item height

Window height in pixels (default: C<600>).

=item resizable

Allow window resizing (default: C<1>).

=item debug

Enable developer tools (default: C<0>).

=item callback

Perl coderef called when JavaScript invokes C<window.external.invoke($arg)>.

=back

=head2 run()

Simple blocking run — shows the window and blocks until it is closed.

=head2 init()

Initialize the webview for manual event loop control. Must be called before
C<loop()>. Injects the Chandra bridge JavaScript automatically.

=head2 loop($blocking)

Process one iteration of the event loop. C<$blocking> is 1 (default) for a
blocking wait or 0 for a non-blocking poll. Returns non-zero when the window
has been closed and the loop should stop.

=head2 eval_js($javascript)

Execute a JavaScript string in the webview. Returns 0 on success.

=head2 dispatch_eval_js($javascript)

Schedule JavaScript evaluation via C<webview_dispatch>. Safe to call from
inside Perl callbacks invoked from the webview thread.

=head2 bind($name, $coderef)

Register a Perl subroutine callable from JavaScript via
C<window.chandra.invoke($name, [args])>. Returns C<$self> for chaining.

=head2 set_title($title)

Change the window title. Returns C<$self>.

=head2 resize($width, $height)

Set the window size.

=head2 inject_css($css)

Inject a CSS stylesheet into the current page. Returns 0 on success.

=head2 set_fullscreen($enable)

Enter (C<1>) or leave (C<0>) fullscreen mode.

=head2 set_color($r, $g, $b, $a)

Set the webview background colour as RGBA values (0-255).

=head2 terminate()

Signal the event loop to stop.

=head2 exit()

Clean up and close the webview.

=head2 title()

Return the current window title.

=head2 url()

Return the current URL.

=head2 width()

Return the window width in pixels.

=head2 height()

Return the window height in pixels.

=head2 resizable()

Return whether the window is resizable (1 or 0).

=head2 debug()

Return whether debug/developer-tools mode is enabled (1 or 0).

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Element>, L<Chandra::Bind>

=head1 LICENSE

MIT License

=cut
