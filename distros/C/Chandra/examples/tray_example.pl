#!/usr/bin/env perl
#
# Example: System Tray with context menu
#
# Demonstrates Chandra::Tray with menu items, separators,
# and callbacks.  The tray icon persists while the app runs.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;

my $app = Chandra::App->new(
    title  => 'Tray Demo',
    width  => 400,
    height => 300,
);

$app->set_content(<<'HTML');
<html>
<body style="font-family:sans-serif;padding:20px">
  <h2>System Tray Demo</h2>
  <p>Right-click the tray icon for the context menu.</p>
  <p id="status">Status: running</p>
</body>
</html>
HTML

my $tray = $app->tray(
    icon    => '',
    tooltip => 'Tray Demo',
);

$tray->add_item('Show Window' => sub {
    # bring window to front (platform-dependent)
});

$tray->add_separator;

$tray->add_item('Say Hello' => sub {
    $app->eval('document.getElementById("status").textContent = "Status: hello from tray!"');
});

$tray->add_separator;

$tray->add_item('Quit' => sub {
    $tray->remove;
    $app->terminate;
});

$tray->show;

$app->run;

=head1 NAME

tray_example.pl - Chandra system tray example

=head1 DESCRIPTION

This example demonstrates how to create a system tray icon with a context menu using Chandra::Tray. It includes menu items that trigger callbacks to update the application status and quit the application.

=cut