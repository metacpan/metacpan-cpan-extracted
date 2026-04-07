package Chandra;

use strict;
use warnings;

our $VERSION = '0.15';

require XSLoader;
XSLoader::load('Chandra', $VERSION);

use Chandra::Bind;
use Chandra::Bridge;

# _xs_dispatch, _xs_init_bind, _xs_bind_method are now XSUBs in core.xs

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

This module is currently underdevelopment and considered alpha experimental quality.
It provides Perl bindings to the webview-c library, allowing you to create
cross-platform GUI applications using web technologies (HTML, CSS, JS).

It should support:
- macOS (WebKit)
- Linux (WebKitGTK)
- Windows (MSHTML/Edge)

See:
- examples/bind_example.pl for a demonstration of JavaScript to Perl function binding.
- examples/counter_app.pl for a more complex example of a counter app with bidirectional communication.

=head1 METHODS

=head2 new(%args)

Create a new Chandra instance.

Options:
- title: Window title (default: 'Chandra')
- url: Initial URL or data URI (default: 'about:blank')
- width: Window width (default: 800)
- height: Window height (default: 600)
- resizable: Allow resizing (default: 1)
- debug: Enable developer tools (default: 0)
- callback: Perl sub called when JS invokes window.external.invoke()

=head2 run()

Simple blocking run - shows window and blocks until closed.

=head2 init()

Initialize the webview for manual event loop control.

=head2 loop($blocking)

Process one event. Returns non-zero when window should close.

=head2 eval_js($javascript)

Execute JavaScript in the webview.

=head2 set_title($title)

Change the window title.

=head2 terminate()

Signal the event loop to stop.

=head2 exit()

Clean up and close the webview.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Element>, L<Chandra::Bind>

=head1 LICENSE

MIT License

=cut
