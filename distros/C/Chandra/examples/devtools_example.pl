#!/usr/bin/env perl
#
# Example: DevTools integration
#
# Demonstrates the Chandra::DevTools panel with error logging,
# bindings inspector, and DOM tree viewer.
#
# Press F12 or Ctrl+Shift+I to toggle the DevTools panel.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;
use Chandra::Element;

my $app = Chandra::App->new(
    title  => 'DevTools Demo',
    width  => 600,
    height => 500,
    debug  => 1,
);

# Enable DevTools and register a reload callback
$app->devtools->on_reload(sub {
    print "[Perl] Reload triggered from DevTools\n";
});

# Register an error handler
$app->on_error(sub {
    my ($err) = @_;
    print "[Perl Error] $err->{context}: $err->{message}\n";
});

# Bind some functions
$app->bind('greet', sub {
    my ($name) = @_;
    return "Hello, $name!";
});

$app->bind('trigger_error', sub {
    die "This is a deliberate error for testing!";
});

# Log a message to the DevTools console
$app->devtools->log("Application started");

my $ui = Chandra::Element->new({
    tag => 'div',
    style => { padding => '20px', 'font-family' => 'sans-serif' },
    children => [
        { tag => 'h1', data => 'DevTools Demo' },
        { tag => 'p', data => 'Press F12 to open the DevTools panel.' },
        {
            tag     => 'button',
            data    => 'Trigger Error',
            style   => 'padding:8px 16px;margin:4px;cursor:pointer;',
            onclick => sub {
                my ($event, $app) = @_;
                $app->eval_js("window.chandra.invoke('trigger_error', [])");
            },
        },
        {
            tag     => 'button',
            data    => 'Say Hello',
            style   => 'padding:8px 16px;margin:4px;cursor:pointer;',
            onclick => sub {
                my ($event, $app) = @_;
                $app->eval_js("window.chandra.invoke('greet', ['World']).then(function(r){ document.getElementById('output').textContent = r; })");
            },
        },
        { tag => 'p', id => 'output', data => '', style => 'color:#333;margin-top:12px;' },
    ],
});

$app->set_content($ui);
$app->run;

=head1 NAME

DevTools Example - Demonstrating Chandra::DevTools integration with error logging and bindings inspection

=head1 DESCRIPTION

This example shows how to use the C<Chandra::DevTools> panel to log messages, handle errors, and inspect bindings. It includes buttons to trigger a test error and to call a bound function, with results displayed in the DevTools console and on the page.

=cut