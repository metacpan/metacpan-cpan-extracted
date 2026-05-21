#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use Chandra::App;
use Chandra::Component;
use Chandra::Nav;
use Chandra::Tabs;
use Chandra::Breadcrumb;
use Chandra::Toast;

my $app = Chandra::App->new(
    title  => 'Navigation Demo',
    width  => 900,
    height => 600,
    debug => 1,
);

$app->theme('dark');
$app->css(Chandra::Nav->css);
$app->css(Chandra::Tabs->css);
$app->css(Chandra::Breadcrumb->css);
$app->css('#layout { display:flex; height:100vh; }');
$app->css('#main { flex:1; padding:24px; overflow-y:auto; }');

# ── Sidebar navigation ────────────────────────────────────

my $nav = Chandra::Nav->new(
    type  => 'sidebar',
    items => [
        { label => 'Dashboard', icon => "\x{1F4CA}", route => '/' },
        { label => 'Users',     icon => "\x{1F465}", route => '/users' },
        { label => 'Messages',  icon => "\x{1F4E8}", route => '/messages', badge => 5 },
        { separator => 1 },
        { label => 'Settings',  icon => "\x{2699}",  route => '/settings' },
        { label => 'Help',      icon => "\x{2753}",  route => '/help' },
    ],
    collapsible => 1,
);

# ── Page content builders ─────────────────────────────────

sub dashboard_page {
    return '<h1>Dashboard</h1><p>Welcome back! Here is your overview.</p>'
         . '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-top:20px;">'
         . '<div style="padding:20px;background:var(--chandra-surface);border-radius:var(--chandra-radius);border:1px solid var(--chandra-border);"><h3 style="margin:0;">128</h3><p style="color:var(--chandra-text-muted);margin:4px 0 0;">Active Users</p></div>'
         . '<div style="padding:20px;background:var(--chandra-surface);border-radius:var(--chandra-radius);border:1px solid var(--chandra-border);"><h3 style="margin:0;">5</h3><p style="color:var(--chandra-text-muted);margin:4px 0 0;">New Messages</p></div>'
         . '<div style="padding:20px;background:var(--chandra-surface);border-radius:var(--chandra-radius);border:1px solid var(--chandra-border);"><h3 style="margin:0;">99.9%</h3><p style="color:var(--chandra-text-muted);margin:4px 0 0;">Uptime</p></div>'
         . '</div>';
}

sub users_page {
    return '<h1>Users</h1><p>User management page.</p>';
}

sub messages_page {
    return '<h1>Messages</h1><p>You have 5 unread messages.</p>';
}

sub settings_page {
    my $tabs = Chandra::Tabs->new(
        tabs => [
            { label => 'General',  content => sub { '<p>General application settings.</p><p>Theme, language, notifications.</p>' } },
            { label => 'Account',  content => sub { '<p>Account settings. Email, password, 2FA.</p>' } },
            { label => 'Plugins',  content => sub { '<p>Manage installed plugins.</p>' }, badge => 2 },
        ],
        on_change => sub {
            my ($i, $label) = @_;
            $app->toast("Switched to $label tab", type => 'info', duration => 1500);
        },
    );
    $tabs->mount($app, '#tabs');
    return '<h1>Settings</h1><div id="tabs"></div>';
}

sub help_page {
    return '<h1>Help</h1>'
         . '<p>This demo shows the navigation components:</p>'
         . '<ul>'
         . '<li><strong>Sidebar</strong> - collapsible with icons, labels, badges</li>'
         . '<li><strong>Tabs</strong> - on the Settings page</li>'
         . '<li><strong>Breadcrumbs</strong> - shown on every page</li>'
         . '<li><strong>Toasts</strong> - shown on tab switch</li>'
         . '</ul>';
}

# ── Route handling ────────────────────────────────────────

my %pages = (
    '/'         => [\&dashboard_page, ['Dashboard']],
    '/users'    => [\&users_page,     ['Dashboard', 'Users']],
    '/messages' => [\&messages_page,  ['Dashboard', 'Messages']],
    '/settings' => [\&settings_page,  ['Dashboard', 'Settings']],
    '/help'     => [\&help_page,      ['Dashboard', 'Help']],
);

my $current_route = '/';

$app->bind('_nav_go', sub {
    my ($route) = @_;
    $current_route = $route;
    render_page($route);
});

sub render_page {
    my ($route) = @_;
    my $info = $pages{$route} // $pages{'/'};
    my ($builder, $crumb_labels) = @$info;

    # Build breadcrumb items
    my @crumb_items;
    my @routes = ('/', $route);
    for my $i (0 .. $#$crumb_labels) {
        my $is_last = $i == $#$crumb_labels;
        push @crumb_items, {
            label => $crumb_labels->[$i],
            ($is_last ? () : (route => $routes[$i] // '/')),
        };
    }

    my $bc = Chandra::Breadcrumb->new(items => \@crumb_items);
    my $page_html = $builder->();

    $app->update('#breadcrumb', $bc->_render_inner);
    $app->update('#page', $page_html);

    # Update nav active state
    $nav->_active($route);
    $nav->update;
}

# Override nav's navigate to use our routing
{
    no warnings 'redefine';
    my $orig = \&Chandra::Nav::on_navigate;
    *Chandra::Nav::on_navigate = sub {
        my ($self, $route) = @_;
        $self->_active($route);
        $self->update;
        render_page($route);
    };
}

# ── Layout ────────────────────────────────────────────────

$app->set_content(<<'HTML');
<div id="layout">
    <div id="nav"></div>
    <div id="main">
        <div id="breadcrumb" style="margin-bottom:16px;"></div>
        <div id="page"></div>
    </div>
</div>
HTML

sub init_app {
    Chandra::Component->reset;
    $nav->mount($app, '#nav');
    render_page($current_route);
}

init_app();

$app->on_reload(sub {
    init_app();
});

$app->run;
