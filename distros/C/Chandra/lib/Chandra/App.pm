package Chandra::App;

use strict;
use warnings;

use Chandra;
use JSON ();

our $VERSION = '0.02';

my $json = JSON->new->utf8->allow_nonref->allow_blessed->convert_blessed;

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

    if (defined $self->{_html}) {
        my $escaped = $self->{_html};
        $escaped =~ s/\\/\\\\/g;
        $escaped =~ s/'/\\'/g;
        $escaped =~ s/\n/\\n/g;
        $escaped =~ s/\r/\\r/g;
        $self->{_webview}->eval_js("document.open();document.write('$escaped');document.close();");
    }

    while ($self->{_webview}->loop(1) == 0) {
        # event loop
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

=head2 terminate()

Signal the event loop to stop.

=head2 webview()

Access the underlying C<Chandra> XS object.

=head2 init() / loop($blocking) / exit()

Low-level lifecycle methods for manual event loop control.

=cut
