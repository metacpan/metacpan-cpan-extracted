#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

use Chandra;
use Chandra::App;
use Chandra::Splash;

# We need a Chandra instance to bootstrap NSApplication and pump the
# macOS event loop so child windows (splash screens) actually render.
my $app = Chandra::App->new(
    title  => 'Splash Demo',
    width  => 1,
    height => 1,
);

# Init the underlying webview — this bootstraps NSApplication
# (setActivationPolicy, finishLaunching, etc.) which is required
# before any child windows will display.
my $wv = $app->webview;
$wv->init;

# Non-blocking event loop pump — call repeatedly to keep GUI alive
sub pump { $wv->loop(0) for 1..5 }

# Pump + sleep helper
sub pump_sleep {
    my ($secs) = @_;
    my $end = time + $secs;
    while (time < $end) {
        pump();
        select(undef, undef, undef, 0.02);
    }
}

print <<'BANNER';
===========================================
  Chandra::Splash — Interactive Demo
===========================================

Commands:
  progress     — Progress bar + status updates
  custom       — Custom HTML content
  frameless    — Frameless splash window
  timeout      — Auto-close after 2 seconds
  app          — $app->splash() convenience wrapper
  quit         — Exit

BANNER

# Helper: show splash, pump events, wait for a key, close
sub show_and_wait {
    my ($s, $msg) = @_;
    $s->show;
    pump();
    print "  $msg\n" if $msg;
    # Pump while waiting for input
    require IO::Select;
    my $sel = IO::Select->new(\*STDIN);
    while (1) {
        pump();
        last if $sel->can_read(0.05);
    }
    my $discard = <STDIN>;
    $s->close;
    pump();
    print "  Closed.\n";
}

while (1) {
    print "> ";
    pump();
    # Non-blocking stdin read with event loop pumping
    require IO::Select;
    my $sel = IO::Select->new(\*STDIN);
    while (!$sel->can_read(0.05)) { pump(); }
    my $cmd = <STDIN>;
    last unless defined $cmd;
    chomp $cmd;
    $cmd =~ s/^\s+|\s+$//g;
    last if $cmd eq 'quit' || $cmd eq 'q' || $cmd eq 'exit';

    if ($cmd eq 'progress') {
        print "Creating progress splash...\n";
        my $s = Chandra::Splash->new(
            title    => 'Loading App',
            width    => 450,
            height   => 220,
            progress => 1,
        );
        $s->show;
        pump();

        my @steps = (
            [ 10,  'Reading configuration...' ],
            [ 30,  'Connecting to database...' ],
            [ 55,  'Loading plugins...' ],
            [ 75,  'Building interface...' ],
            [ 90,  'Final checks...' ],
            [ 100, 'Ready!' ],
        );

        for my $step (@steps) {
            $s->update_progress($step->[0]);
            $s->update_status($step->[1]);
            print "  [$step->[0]%] $step->[1]\n";
            pump_sleep(0.6);
        }

        pump_sleep(0.5);
        $s->close;
        pump();
        print "  Done.\n";

    } elsif ($cmd eq 'custom') {
        print "Creating custom HTML splash...\n";
        my $s = Chandra::Splash->new(
            width   => 500,
            height  => 300,
            content => <<'HTML',
<!DOCTYPE html>
<html>
<head><style>
body {
    margin: 0; display: flex; align-items: center; justify-content: center;
    height: 100vh; background: linear-gradient(135deg, #667eea, #764ba2);
    font-family: -apple-system, sans-serif; color: white;
}
.container { text-align: center; }
h1 { font-size: 2em; margin-bottom: 8px; }
p { opacity: 0.8; font-size: 1.1em; }
.dots::after {
    content: '';
    animation: dots 1.5s steps(4, end) infinite;
}
@keyframes dots {
    0%   { content: ''; }
    25%  { content: '.'; }
    50%  { content: '..'; }
    75%  { content: '...'; }
    100% { content: ''; }
}
</style></head>
<body>
<div class="container">
    <h1>✨ My App</h1>
    <p>Version 3.0</p>
    <p class="dots">Loading</p>
</div>
</body>
</html>
HTML
        );
        show_and_wait($s, 'Press Enter to close...');

    } elsif ($cmd eq 'frameless') {
        print "Creating frameless splash...\n";
        my $s = Chandra::Splash->new(
            width     => 400,
            height    => 200,
            frameless => 1,
            content   => <<'HTML',
<div style="display:flex;align-items:center;justify-content:center;
            height:100vh;background:#222;color:#0f0;
            font-family:monospace;font-size:1.3em;">
    <span>SYSTEM LOADING...</span>
</div>
HTML
        );
        show_and_wait($s, 'Press Enter to close...');

    } elsif ($cmd eq 'timeout') {
        print "Creating splash with 2s timeout...\n";
        my $s = Chandra::Splash->new(
            title    => 'Auto-Close',
            progress => 1,
            timeout  => 2000,
        );
        $s->show;
        $s->update_status('Closing in 2 seconds...');
        pump();

        # Poll for expiration while pumping events
        while (!$s->close_if_expired) {
            pump();
            select(undef, undef, undef, 0.05);
        }
        pump();
        print "  Auto-closed.\n";

    } elsif ($cmd eq 'app') {
        print "Running \$app->splash() with init callback...\n";
        $app->splash(
            progress => 1,
            init     => sub {
                my ($s) = @_;
                for my $i (1..5) {
                    $s->update_status("Init step $i/5...");
                    $s->update_progress($i * 20);
                    print "  Step $i\n";
                    pump_sleep(0.4);
                }
            },
        );
        pump();
        print "  Splash finished.\n";

    } elsif ($cmd eq '') {
        next;
    } else {
        print "Unknown command: $cmd\n";
    }

    print "\n";
}

print "Bye!\n";
