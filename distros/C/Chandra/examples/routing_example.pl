#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;

my $app = Chandra::App->new(
    title  => 'Routing Example',
    width  => 600,
    height => 400,
    debug  => 1,
);

# Shared layout — navigation bar + content container
$app->layout(sub {
    my ($body) = @_;
    return qq{
        <style>
            body { font-family: -apple-system, sans-serif; margin: 0; background: #f5f5f5; }
            nav { background: #2c3e50; padding: 12px 20px; }
            nav a { color: #ecf0f1; text-decoration: none; margin-right: 16px; font-size: 14px; }
            nav a:hover { color: #3498db; }
            #chandra-content { padding: 20px; max-width: 560px; }
            h1 { color: #2c3e50; margin-top: 0; }
            p { color: #555; line-height: 1.6; }
            .card { background: #fff; border-radius: 6px; padding: 16px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        </style>
        <nav>
            <a href="/">Home</a>
            <a href="/about">About</a>
            <a href="/contact">Contact</a>
            <a href="/user/42">User 42</a>
        </nav>
        <div id="chandra-content">$body</div>
    };
});

# Home page
$app->route('/' => sub {
    return qq{
        <h1>Home</h1>
        <div class="card">
            <p>Welcome to the Chandra routing example. Click the links
            in the navigation bar to switch between pages.</p>
            <p>All navigation happens client-side within a single webview
            window — no page reloads.</p>
        </div>
    };
});

# About page
$app->route('/about' => sub {
    return qq{
        <h1>About</h1>
        <div class="card">
            <p>Chandra is a Perl module for building cross-platform GUI
            applications using web technologies with native webview rendering.</p>
        </div>
        <div class="card">
            <p>The routing system is built into Chandra::App. Register routes
            with <code>\$app-&gt;route()</code> and add a shared layout with
            <code>\$app-&gt;layout()</code>.</p>
        </div>
    };
});

# Contact page
$app->route('/contact' => sub {
    return qq{
        <h1>Contact</h1>
        <div class="card">
            <p>Email: hello\@example.com</p>
            <p>GitHub: github.com/example/chandra</p>
        </div>
    };
});

# Parameterised route
$app->route('/user/:id' => sub {
    my (%params) = @_;
    return qq{
        <h1>User Profile</h1>
        <div class="card">
            <p><strong>User ID:</strong> $params{id}</p>
            <p>This page demonstrates route parameters.
            The <code>:id</code> segment was captured from the URL.</p>
        </div>
    };
});

# Custom 404
$app->not_found(sub {
    return qq{
        <h1>404 — Page Not Found</h1>
        <div class="card">
            <p>The page you requested does not exist.
            <a href="/">Go home</a>.</p>
        </div>
    };
});

$app->run;

=head1 NAME

Routing Example - A simple client-side routing system for Chandra apps

=head1 DESCRIPTION

This example demonstrates how to implement a client-side routing system in a Chandra application. It defines multiple routes with C<\$app->route()> and a shared layout with C<\$app->layout()>. When the user clicks on navigation links, the content updates without reloading the page, and route parameters are supported for dynamic URLs. A custom 404 handler is also included for unmatched routes.

=cut