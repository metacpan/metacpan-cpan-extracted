package Chandra::App;

use strict;
use warnings;

use Chandra;
use Chandra::Bridge;
use Cpanel::JSON::XS ();

our $VERSION = '0.15';

1;

__END__

=head1 NAME

Chandra::App - High-level application wrapper for Chandra

=head1 SYNOPSIS

	use Chandra::App;

	my $app = Chandra::App->new(
	    title  => 'My App',
	    width  => 800,
	    height => 600,
	);

	$app->bind('greet', sub {
	    my ($name) = @_;
	    return "Hello, $name!";
	});

	$app->set_content('<h1>Hello World</h1><button onclick="window.chandra.invoke(\'greet\',[\'World\']).then(r=>document.title=r)">Greet</button>');

	$app->run;

	# --- Routing Example ---

	use Chandra::Element;

	my $spa = Chandra::App->new(title => 'My SPA', width => 800, height => 600);

	$spa->layout(sub {
	    my ($body) = @_;
	    Chandra::Element->new({
	        tag => 'div',
	        children => [
	            {
	                tag => 'nav',
	                children => [
	                    { tag => 'a', href => '/',      data => 'Home' },
	                    { tag => 'a', href => '/about', data => ' | About' },
	                ]
	            },
	            { tag => 'div', id => 'chandra-content', raw => $body },
	        ],
	    });
	});

	# Global CSS applied to every route
	$spa->css('body { font-family: sans-serif; margin: 0; }');
	$spa->css('nav a { padding: 8px; color: #333; text-decoration: none; }');

	# Global JS executed on every page
	$spa->js('console.log("App loaded");');

	$spa->route('/' => sub {
	    Chandra::Element->new(
	        tag => 'div',
	        children => [
	            { tag => 'h1', data => 'Home' },
	            { tag => 'p',  data => 'Welcome!' },
	        ],
	    );
	});

	# Per-route CSS and JS via route options
	$spa->route('/about' => sub {
	    Chandra::Element->new(
	        tag => 'div',
	        children => [
	            { tag => 'h1', data => 'About' },
	            { tag => 'p',  data => 'Info here' },
	        ],
	    );
	}, css => 'h1 { color: navy; }', js => 'console.log("About page");');

	$spa->route('/user/:id' => sub {
	    my (%params) = @_;
	    Chandra::Element->new(
	        tag => 'h1', data => "User $params{id}",
	    );
	});

	$spa->not_found(sub {
	    Chandra::Element->new(tag => 'h1', data => '404 - Not Found');
	});

	$spa->run;

=head1 DESCRIPTION

Chandra::App provides a clean, high-level OO interface on top of the
XS-backed Chandra module. It manages the webview lifecycle and provides
convenience methods for setting content, updating the DOM, and running
JavaScript.

=head1 METHODS

=head2 new(%args)

Create a new application. Accepts all the same options as C<Chandra-E<gt>new>:
title, url, width, height, resizable, debug.

=head2 run()

Initialize the webview, inject any set_content HTML, and enter the event loop.
Blocks until the window is closed.

=head2 bind($name, $coderef)

Register a Perl subroutine callable from JavaScript via
C<window.chandra.invoke($name, [args])>.

=head2 set_content($html_or_element)

Set the page content. Accepts a plain HTML string or any object that
responds to C<render()> (e.g., a future Chandra::Element).

=head2 update($selector, $html_or_element)

Replace the innerHTML of the element matching C<$selector>.

=head2 eval($js)

Execute JavaScript in the webview.

=head2 dispatch_eval($js)

Deferred JavaScript evaluation, safe to call from within Perl callbacks.

=head2 set_title($title)

Change the window title.

=head2 alert($message)

Show a JavaScript alert dialog.

=head2 devtools()

Return the L<Chandra::DevTools> instance for this application.
Creates and enables it on first call.  The DevTools panel can be
toggled in the browser with B<F12> or B<Ctrl+Shift+I>.

=head2 on_error($coderef)

Register a callback invoked when an error is captured by
L<Chandra::Error>.  The callback receives a hashref with C<message>,
C<context>, C<trace>, and C<time>.

=head2 watch($path, $coderef)

Watch a file or directory for changes.  When modifications are detected
the callback is invoked with an arrayref of changed paths.  Activates
L<Chandra::HotReload> polling inside C<run()>.

=head2 refresh()

Re-inject the current C<set_content> HTML and re-apply DevTools.
Useful inside hot-reload callbacks.

=head2 dialog()

Return the L<Chandra::Dialog> instance for opening native file and
alert dialogs.

=head2 protocol()

Return the L<Chandra::Protocol> instance for registering custom URL
scheme handlers (e.g. C<myapp://path>).

=head2 drag_drop()

Return the L<Chandra::DragDrop> instance for advanced drag-and-drop
configuration (make_draggable, on_internal_drop, etc.).

=head2 on_file_drop($coderef)

Register a global file-drop handler.  Convenience wrapper for
C<< $app->drag_drop->on_file_drop($cb) >>.

    $app->on_file_drop(sub {
        my ($files) = @_;
        print "Dropped: $_\n" for @$files;
    });

=head2 drop_zone($selector, $coderef)

Register a zone-specific drop handler.  Convenience wrapper for
C<< $app->drag_drop->add_drop_zone($sel, $cb) >>.

    $app->drop_zone('#upload-area', sub {
        my ($files, $target) = @_;
    });

=head2 inject_css($css)

Inject a CSS stylesheet into the current page.

=head2 fullscreen($enable)

Enter or leave fullscreen mode.  Pass C<1> to enable, C<0> to disable.

=head2 set_color($r, $g, $b, $a)

Set the webview background colour as RGBA (0-255).  Alpha defaults to 255.

=head2 terminate()

Signal the event loop to stop.

=head2 route($path, $coderef, %opts)

Register a route.  When the application is in routing mode (at least one
route registered), C<run()> renders the initial route instead of using
C<set_content>.  The coderef should return an HTML string or an object
with a C<render()> method.

	$app->route('/' => sub { '<h1>Home</h1>' });

Route parameters are supported with C<:param> placeholders:

	$app->route('/user/:id' => sub {
	    my (%params) = @_;
	    "<h1>User $params{id}</h1>";
	});

Optional C<css> and C<js> arguments inject route-specific styles and
scripts that are swapped in on each navigation:

	$app->route('/about' => sub { '<h1>About</h1>' },
	    css => 'h1 { color: navy; }',
	    js  => 'console.log("about loaded");',
	);

=head2 css($css_string)

Append a global CSS block.  All blocks are concatenated and injected into
a C<< <style id="chandra-global-css"> >> element in the document head
after the initial content is loaded.  Can be called multiple times;
each call adds to the list.

	$app->css('body { font-family: sans-serif; }');
	$app->css('nav { background: #eee; }');

=head2 js($js_string)

Append a global JavaScript block.  All blocks are concatenated and
injected into a C<< <script id="chandra-global-js"> >> element at the
end of the document body after all other post-content scripts.  Can be
called multiple times; each call adds to the list.

	$app->js('console.log("ready");');

=head2 layout($coderef)

Set a layout wrapper applied to every route.  The coderef receives the
rendered page body as its argument and must return the full HTML.
Include an element with C<id="chandra-content"> for partial updates:

	$app->layout(sub {
	    my ($body) = @_;
	    "<nav>...</nav><div id='chandra-content'>$body</div>";
	});

=head2 navigate($path)

Navigate to a registered route.  If the application is running, the
content is updated in-place and a history entry is pushed.

=head2 not_found($coderef)

Set a custom 404 handler for unmatched routes.  Defaults to a simple
C<< <h1>404 - Not Found</h1> >> page.

=head2 webview()

Access the underlying C<Chandra> XS object.

=head2 init() / loop($blocking) / exit()

Low-level lifecycle methods for manual event loop control.

=head1 SEE ALSO

L<Chandra>, L<Chandra::Element>, L<Chandra::Bind>, L<Chandra::DevTools>,
L<Chandra::HotReload>, L<Chandra::Dialog>, L<Chandra::Protocol>,
L<Chandra::DragDrop>, L<Chandra::Socket::Hub>, L<Chandra::Socket::Client>

=cut
