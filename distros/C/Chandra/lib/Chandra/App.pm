package Chandra::App;

use strict;
use warnings;

use Chandra;
use Chandra::Bridge;
use Cpanel::JSON::XS ();

our $VERSION = '0.06';

my $json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

sub _escape_js {
	my ($str) = @_;
	$str =~ s/\\/\\\\/g;
	$str =~ s/'/\\'/g;
	$str =~ s/\n/\\n/g;
	$str =~ s/\r/\\r/g;
	return $str;
}

sub new {
	my ($class, %args) = @_;

	my $self = bless {
		_webview => undef,
		_started => 0,
	}, $class;

	$self->{_webview} = Chandra->new(%args);

	return $self;
}

# Delegate accessors to the underlying webview
sub title     { shift->{_webview}->title }
sub url       { shift->{_webview}->url }
sub width     { shift->{_webview}->width }
sub height    { shift->{_webview}->height }
sub resizable { shift->{_webview}->resizable }
sub debug     { shift->{_webview}->debug }

# Bind a Perl sub callable from JavaScript
sub bind {
	my ($self, $name, $sub) = @_;
	$self->{_webview}->bind($name, $sub);
	return $self;
}

# Register a route — path => coderef
sub route {
	my ($self, $path, $handler) = @_;
	$self->{_routes} ||= [];
	push @{ $self->{_routes} }, [ $path, $handler ];
	return $self;
}

# Set a layout wrapper — coderef receives rendered body HTML
sub layout {
	my ($self, $handler) = @_;
	$self->{_layout} = $handler;
	return $self;
}

# Set a 404 fallback handler
sub not_found {
	my ($self, $handler) = @_;
	$self->{_not_found} = $handler;
	return $self;
}

# Navigate to a route path
sub navigate {
	my ($self, $path) = @_;
	$self->{_current_route} = $path;

	if ($self->{_started}) {
		# Partial update: only the body goes into #chandra-content
		my $body = _escape_js($self->_render_route_body($path));
		# Full update fallback (no layout / no container)
		my $full = _escape_js($self->_render_route($path));
		$self->{_webview}->dispatch_eval_js(
			"var _c=document.getElementById('chandra-content');"
			. "if(_c){_c.innerHTML='$body';}"
			. "else{document.open();document.write('$full');document.close();}"
			. "history.pushState({},'','$path');"
		);
	}
	return $self;
}

# Match a path against registered routes, returns ($handler, %params) or ()
sub _match_route {
	my ($self, $path) = @_;
	return () unless $self->{_routes};

	for my $entry (@{ $self->{_routes} }) {
		my ($pattern, $handler) = @$entry;
		my @pat_parts = split m{/}, $pattern, -1;
		my @path_parts = split m{/}, $path, -1;

		next if @pat_parts != @path_parts;

		my %params;
		my $match = 1;
		for my $i (0 .. $#pat_parts) {
			if ($pat_parts[$i] =~ /^:(.+)$/) {
				$params{$1} = $path_parts[$i];
			} elsif ($pat_parts[$i] ne $path_parts[$i]) {
				$match = 0;
				last;
			}
		}
		return ($handler, %params) if $match;
	}
	return ();
}

# Render a route's body content (no layout)
sub _render_route_body {
	my ($self, $path) = @_;

	my ($handler, %params) = $self->_match_route($path);
	unless ($handler) {
		$handler = $self->{_not_found} || sub { '<h1>404 - Not Found</h1>' };
	}

	my $content = $handler->(%params);
	if (ref $content && $content->can('render')) {
		return $content->render;
	}
	return "$content";
}

# Render a route path to full HTML (with layout)
sub _render_route {
	my ($self, $path) = @_;
	my $body = $self->_render_route_body($path);
	if ($self->{_layout}) {
		my $result = $self->{_layout}->($body);
		if (ref $result && $result->can('render')) {
			return $result->render;
		}
		return "$result";
	}
	return $body;
}

# Generate JS router code
sub _router_js {
	return <<'JS';
(function(){
  document.addEventListener('click', function(e) {
    var el = e.target;
    while (el && el.tagName !== 'A') el = el.parentElement;
    if (!el) return;
    var href = el.getAttribute('href');
    if (!href || href.match(/^https?:\/\//) || href.match(/^#/)) return;
    e.preventDefault();
    window.chandra.invoke('__chandra_navigate', [href]);
  });
  window.addEventListener('popstate', function() {
    window.chandra.invoke('__chandra_navigate', [location.pathname || '/']);
  });
})();
JS
}

# Inject post-content JS (devtools, protocols, router)
sub _inject_post_content_js {
	my ($self, $dispatch) = @_;
	my $method = $dispatch ? 'dispatch_eval_js' : 'eval_js';

	if ($self->{_devtools} && $self->{_devtools}->is_enabled) {
		$self->{_webview}->$method(Chandra::DevTools->js_code);
	}
	if ($self->{_protocol} && scalar $self->{_protocol}->schemes) {
		if ($dispatch) {
			$self->{_webview}->dispatch_eval_js($self->{_protocol}->js_code);
		} else {
			$self->{_protocol}->inject;
		}
	}
	if ($self->{_routes}) {
		$self->{_webview}->$method($self->_router_js);
	}
}

# Set the full page content from HTML string or object with render()
sub set_content {
	my ($self, $content) = @_;

	my $html;
	if (ref $content && $content->can('render')) {
		$html = $content->render;
	} else {
		$html = "$content";
	}

	$self->{_html} = $html;
	return $self;
}

# Simple blocking run - init, set content, enter event loop
sub run {
	my ($self) = @_;

	$self->{_webview}->init;
	$self->{_started} = 1;

	# Activate pending tray (must happen after init establishes GUI connection)
	if ($self->{_tray} && $self->{_tray}{_pending}) {
		$self->{_tray}->show;
	}

	# Routing mode: bind navigator and render initial route
	if ($self->{_routes}) {
		$self->{_webview}->bind('__chandra_navigate', sub {
				my ($path) = @_;
				$self->navigate($path);
				return;
			});
		my $initial = $self->{_current_route} || '/';
		$self->{_current_route} = $initial;
		my $html = $self->_render_route($initial);
		my $escaped = _escape_js($html);
		$self->{_webview}->eval_js("document.open();document.write('$escaped');document.close();");
	} elsif (defined $self->{_html}) {
		my $escaped = _escape_js($self->{_html});
		$self->{_webview}->eval_js("document.open();document.write('$escaped');document.close();");
	}

	$self->_inject_post_content_js(0);

	# Use non-blocking loop when hot reload or IPC is active
	my $blocking = ($self->{_hot_reload} || $self->{_hub} || $self->{_client}) ? 0 : 1;
	while ($self->{_webview}->loop($blocking) == 0) {
		$self->{_hot_reload}->poll if $self->{_hot_reload};
		$self->{_hub}->poll        if $self->{_hub};
		$self->{_client}->poll     if $self->{_client};
		select(undef, undef, undef, 0.01) if !$blocking;
	}

	$self->{_webview}->exit;
	$self->{_started} = 0;
}

# Evaluate JavaScript in the webview
sub eval {
	my ($self, $js) = @_;
	return $self->{_webview}->eval_js($js);
}

# Deferred eval safe to call from within callbacks
sub dispatch_eval {
	my ($self, $js) = @_;
	$self->{_webview}->dispatch_eval_js($js);
}

# Update a DOM element matched by CSS selector with new content
sub update {
	my ($self, $selector, $content) = @_;

	my $html;
	if (ref $content && $content->can('render')) {
		$html = $content->render;
	} else {
		$html = "$content";
	}

	my $escaped = $html;
	$escaped =~ s/\\/\\\\/g;
	$escaped =~ s/'/\\'/g;
	$escaped =~ s/\n/\\n/g;
	$escaped =~ s/\r/\\r/g;

	my $sel_escaped = $selector;
	$sel_escaped =~ s/\\/\\\\/g;
	$sel_escaped =~ s/'/\\'/g;

	my $js = "var _el=document.querySelector('$sel_escaped');if(_el){_el.innerHTML='$escaped';}";
	$self->{_webview}->dispatch_eval_js($js);
}

# Change the window title
sub set_title {
	my ($self, $title) = @_;
	$self->{_webview}->set_title($title);
	return $self;
}

# Convenience: show a JS alert dialog
sub alert {
	my ($self, $message) = @_;
	my $encoded = $json->encode("$message");
	$self->{_webview}->dispatch_eval_js("alert($encoded)");
}

# Access or create the DevTools instance
sub devtools {
	my ($self) = @_;
	unless ($self->{_devtools}) {
		require Chandra::DevTools;
		$self->{_devtools} = Chandra::DevTools->new(app => $self);
		$self->{_devtools}->enable;
	}
	return $self->{_devtools};
}

# Register an error handler
sub on_error {
	my ($self, $handler) = @_;
	require Chandra::Error;
	Chandra::Error->on_error($handler);
	return $self;
}

# Watch files for hot reload
sub watch {
	my ($self, $path, $callback) = @_;
	require Chandra::HotReload;
	$self->{_hot_reload} //= Chandra::HotReload->new;
	$self->{_hot_reload}->watch($path, $callback);
	return $self;
}

# Refresh the current content (re-inject HTML + DevTools)
sub refresh {
	my ($self) = @_;

	if ($self->{_routes} && $self->{_current_route}) {
		my $html = $self->_render_route($self->{_current_route});
		my $escaped = _escape_js($html);
		$self->{_webview}->dispatch_eval_js("document.open();document.write('$escaped');document.close();");
		$self->_inject_post_content_js(1);
	} elsif (defined $self->{_html}) {
		my $escaped = _escape_js($self->{_html});
		$self->{_webview}->dispatch_eval_js("document.open();document.write('$escaped');document.close();");
		$self->_inject_post_content_js(1);
	}
	return $self;
}

# Access or create the Dialog instance
sub dialog {
	my ($self) = @_;
	unless ($self->{_dialog}) {
		require Chandra::Dialog;
		$self->{_dialog} = Chandra::Dialog->new(app => $self);
	}
	return $self->{_dialog};
}

# Access or create the Tray instance
sub tray {
	my ($self, %args) = @_;
	unless ($self->{_tray}) {
		require Chandra::Tray;
		$self->{_tray} = Chandra::Tray->new(app => $self, %args);
	}
	return $self->{_tray};
}

# Access or create the Protocol instance
sub protocol {
	my ($self) = @_;
	unless ($self->{_protocol}) {
		require Chandra::Protocol;
		$self->{_protocol} = Chandra::Protocol->new(app => $self);
	}
	return $self->{_protocol};
}

# Access or create a Hub (IPC server)
sub hub {
	my ($self, %args) = @_;
	unless ($self->{_hub}) {
		require Chandra::Socket::Hub;
		$self->{_hub} = Chandra::Socket::Hub->new(%args);
	}
	return $self->{_hub};
}

# Access or create a Client (IPC client)
sub client {
	my ($self, %args) = @_;
	unless ($self->{_client}) {
		require Chandra::Socket::Client;
		$self->{_client} = Chandra::Socket::Client->new(%args);
	}
	return $self->{_client};
}

# Inject CSS into the webview
sub inject_css {
	my ($self, $css) = @_;
	$self->{_webview}->inject_css($css);
	return $self;
}

# Set fullscreen mode
sub fullscreen {
	my ($self, $enable) = @_;
	$enable //= 1;
	$self->{_webview}->set_fullscreen($enable);
	return $self;
}

# Set background color (RGBA)
sub set_color {
	my ($self, $r, $g, $b, $a) = @_;
	$a //= 255;
	$self->{_webview}->set_color($r, $g, $b, $a);
	return $self;
}

# Signal the event loop to stop
sub terminate {
	my ($self) = @_;
	$self->{_webview}->terminate;
}

# Access the underlying Chandra (XS) object
sub webview {
	return shift->{_webview};
}

# Low-level lifecycle access
sub init {
	my ($self) = @_;
	$self->{_webview}->init;
	$self->{_started} = 1;
	return $self;
}

sub loop {
	my ($self, $blocking) = @_;
	$blocking //= 1;
	return $self->{_webview}->loop($blocking);
}

sub exit {
	my ($self) = @_;
	if ($self->{_started}) {
		$self->{_webview}->exit;
		$self->{_started} = 0;
	}
}

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

	$spa->route('/' => sub {
	    Chandra::Element->new(
	        tag => 'div',
	        children => [
	            { tag => 'h1', data => 'Home' },
	            { tag => 'p',  data => 'Welcome!' },
	        ],
	    );
	});

	$spa->route('/about' => sub {
	    Chandra::Element->new(
	        tag => 'div',
	        children => [
	            { tag => 'h1', data => 'About' },
	            { tag => 'p',  data => 'Info here' },
	        ],
	    );
	});

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

=head2 inject_css($css)

Inject a CSS stylesheet into the current page.

=head2 fullscreen($enable)

Enter or leave fullscreen mode.  Pass C<1> to enable, C<0> to disable.

=head2 set_color($r, $g, $b, $a)

Set the webview background colour as RGBA (0-255).  Alpha defaults to 255.

=head2 terminate()

Signal the event loop to stop.

=head2 route($path, $coderef)

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
L<Chandra::Socket::Hub>, L<Chandra::Socket::Client>

=cut
