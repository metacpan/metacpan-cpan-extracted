#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 22;

BEGIN {
    use_ok('Chandra::Nav');
    use_ok('Chandra::Tabs');
    use_ok('Chandra::Breadcrumb');
}

Chandra::Component->reset;
Chandra::Element->reset_ids;

# ── Nav ──────────────────────────────────────────────────

my $nav = Chandra::Nav->new(
    type  => 'sidebar',
    items => [
        { label => 'Home',     icon => 'H', route => '/' },
        { label => 'Users',    icon => 'U', route => '/users' },
        { separator => 1 },
        { label => 'Settings', icon => 'S', route => '/settings', badge => 3 },
    ],
    collapsible => 1,
);

ok($nav, 'Nav created');
isa_ok($nav, 'Chandra::Component');

my $nav_html = $nav->render;
like($nav_html, qr/chandra-nav-sidebar/, 'sidebar class');
like($nav_html, qr/Home/, 'has Home item');
like($nav_html, qr/Users/, 'has Users item');
like($nav_html, qr/Settings/, 'has Settings item');
like($nav_html, qr/chandra-nav-separator/, 'has separator');
like($nav_html, qr/chandra-nav-badge/, 'has badge');
like($nav_html, qr/chandra-nav-toggle/, 'has toggle button');

# Topbar variant
my $topbar = Chandra::Nav->new(
    type  => 'topbar',
    items => [{ label => 'Dash', route => '/' }],
);
like($topbar->render, qr/chandra-nav-topbar/, 'topbar class');

# CSS
my $nav_css = Chandra::Nav->css;
like($nav_css, qr/chandra-nav-sidebar/, 'CSS has sidebar styles');
like($nav_css, qr/chandra-nav-topbar/, 'CSS has topbar styles');

# ── Tabs ─────────────────────────────────────────────────

my $tabs = Chandra::Tabs->new(
    tabs => [
        { label => 'General',  content => sub { '<p>Gen</p>' } },
        { label => 'Advanced', content => sub { '<p>Adv</p>' } },
        { label => 'Plugins',  content => sub { '<p>Plug</p>' }, badge => 5 },
    ],
);

ok($tabs, 'Tabs created');

my $tabs_html = $tabs->render;
like($tabs_html, qr/General/, 'has General tab');
like($tabs_html, qr/Advanced/, 'has Advanced tab');
like($tabs_html, qr/chandra-tab-active/, 'first tab active');
like($tabs_html, qr/<p>Gen<\/p>/, 'renders first tab content');

# ── Breadcrumb ───────────────────────────────────────────

my $bc = Chandra::Breadcrumb->new(
    items => [
        { label => 'Home',  route => '/' },
        { label => 'Users', route => '/users' },
        { label => 'Alice' },
    ],
);

ok($bc, 'Breadcrumb created');
my $bc_html = $bc->render;
like($bc_html, qr/Alice/, 'has current item');

done_testing;
