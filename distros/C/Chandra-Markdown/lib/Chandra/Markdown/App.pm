package Chandra::Markdown::App;

use strict;
use warnings;
use Object::Proto::Sugar -constants;
use Chandra::App;
use Chandra::Markdown;
use Chandra::Element;

our $VERSION = '0.01';

has title       => (is_ro, default => 'Documentation');
has width       => (is_ro, default => 1100);
has height      => (is_ro, default => 750);
has docs_dir    => (is_ro, req);
has base_route  => (is_ro, default => '/docs');
has nav_id      => (is_ro, default => 'chandra-markdown-nav');
has recursive   => (is_ro, default => 1);
has brand       => (is_ro, default => 'Documentation');
has placeholder => (is_ro, default => 'Search docs...');
has _app        => (is_rw, lzy, bld);
has _md         => (is_rw, lzy, bld);

sub _build__app {
    my ($self) = @_;
    Chandra::App->new(
        title  => $self->title,
        width  => $self->width,
        height => $self->height,
    );
}

sub _build__md {
    my ($self) = @_;
    Chandra::Markdown->new(app => $self->_app);
}

sub BUILD {
    my ($self) = @_;
    my $app    = $self->_app;
    my $md     = $self->_md;
    my $nav_id = $self->nav_id;
    my $brand  = $self->brand;

    my $nav = $md->render_dir($self->docs_dir,
        base_route => $self->base_route,
        recursive  => $self->recursive,
        nav_id     => $nav_id,
    );
    my $search = $md->search_widget(placeholder => $self->placeholder);

    $app->css(_shell_css());

    $app->layout(sub {
        my ($body) = @_;

        my $shell = Chandra::Element->new({ tag => 'div', id => 'chandra-shell' });

        my $sidebar = Chandra::Element->new({ tag => 'aside', id => 'chandra-sidebar' });
        $sidebar->add_child(Chandra::Element->new({ tag => 'div', raw => $search }));
	$sidebar->add_child(Chandra::Element->new({
            tag  => 'div',
            id   => 'chandra-sidebar-brand',
            data => $brand,
        }));
        $sidebar->add_child(Chandra::Element->new({ tag => 'div', raw => $nav }));
        $shell->add_child($sidebar);

        my $pane = Chandra::Element->new({ tag => 'div', id => 'chandra-content-pane' });
        $pane->add_child(Chandra::Element->new({
            tag   => 'div',
            id    => 'chandra-content',
            class => 'chandra-markdown',
            raw   => $body,
        }));
        $shell->add_child($pane);

        return $shell->render
             . Chandra::Element->new({ tag => 'script', raw => _active_link_js($nav_id) })->render;
    });

    my $docs_dir = $self->docs_dir;
    $app->route('/' => sub {
        open my $fh, '<:utf8', "$docs_dir/index.md"
            or return Chandra::Element->new({ tag => 'p', data => 'No index found.' })->render;
        local $/;
        $md->render(scalar <$fh>);
    });
}

sub run {
    my ($self) = @_;
    $self->_app->run;
}

sub _active_link_js {
    my ($nav_id) = @_;
    return "(function(){"
         . "function markActive(){"
         .     "var path=location.pathname||'/';"
         .     "var links=document.querySelectorAll('#${nav_id} a');"
         .     "for(var i=0;i<links.length;i++){"
         .         "links[i].classList.toggle('active',links[i].getAttribute('href')===path);"
         .     "}}"
         . "markActive();"
         . "var c=document.getElementById('chandra-content');"
         . "if(c){"
         .     "new MutationObserver(function(){setTimeout(markActive,0);})"
         .         ".observe(c,{childList:true});"
         . "}"
         . "})();";
}

sub _shell_css {
    return <<'END_CSS';
*, *::before, *::after { box-sizing: border-box; }
html, body { height: 100%; margin: 0; }

#chandra-shell {
    display: flex;
    height: 100vh;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: var(--chandra-bg, #ffffff);
    color: var(--chandra-text, #24292f);
}

#chandra-sidebar {
    width: 240px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    border-right: 1px solid var(--chandra-border, #d0d7de);
    background: var(--chandra-sidebar-bg, #f6f8fa);
    overflow-y: auto;
}

#chandra-sidebar-brand {
    padding: 18px 16px 14px;
    font-size: 12px;
    font-weight: 600;
    letter-spacing: .07em;
    text-transform: uppercase;
    color: var(--chandra-muted, #57606a);
    border-bottom: 1px solid var(--chandra-border, #d0d7de);
    user-select: none;
}

#chandra-markdown-nav ul {
    list-style: none;
    margin: 0;
    padding: 8px 0;
}

#chandra-markdown-nav li a {
    display: block;
    padding: 7px 16px;
    font-size: 13.5px;
    color: var(--chandra-text, #24292f);
    text-decoration: none;
    border-left: 3px solid transparent;
    transition: background 120ms, color 120ms, border-color 120ms;
}

#chandra-markdown-nav li a:hover {
    background: var(--chandra-hover, #eaeef2);
    color: var(--chandra-link, #0969da);
    border-left-color: var(--chandra-link, #0969da);
}

#chandra-markdown-nav li a.active {
    background: var(--chandra-active-bg, #dbeafe);
    color: var(--chandra-link, #0969da);
    border-left-color: var(--chandra-link, #0969da);
    font-weight: 500;
}

#chandra-content-pane {
    flex: 1;
    overflow-y: auto;
}

#chandra-content.chandra-markdown {
    max-width: 800px;
    padding: 32px 40px;
}
END_CSS
}

1;

__END__

=head1 NAME

Chandra::Markdown::App - Ready made markdown docs site application for Chandra

=head1 SYNOPSIS

    use Chandra::Markdown::App;

    Chandra::Markdown::App->new(
        docs_dir => '/path/to/docs',
        title    => 'My Docs',
    )->run;

=head1 DESCRIPTION

Wraps L<Chandra::Markdown> into a complete single call application: sidebar
navigation, full-text search widget, active link highlighting, and a default
C</> route that renders C<index.md>.

=head1 ATTRIBUTES

=over 4

=item docs_dir (required)

Path to the directory containing C<.md> files.

=item title

Window title. Default: C<'Documentation'>.

=item width / height

Window dimensions. Defaults: 1100 x 750.

=item base_route

URL prefix for doc routes. Default: C<'/docs'>.

=item nav_id

HTML id of the C<< <nav> >> element. Default: C<'chandra-markdown-nav'>.

=item recursive

Scan subdirectories. Default: C<1>.

=item brand

Sidebar header text. Default: C<'Documentation'>.

=item placeholder

Search input placeholder. Default: C<'Search docs...'>.

=back

=head1 METHODS

=head2 run

Start the Chandra event loop.

=head1 SEE ALSO

L<Chandra::Markdown>, L<Chandra::App>

=cut
