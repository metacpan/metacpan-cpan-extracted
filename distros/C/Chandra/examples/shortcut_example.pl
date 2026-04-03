#!/usr/bin/env perl
use strict;
use warnings;
use Chandra::App;

my $app = Chandra::App->new(
    title  => 'Shortcut Demo',
    width  => 600,
    height => 400,
);

# Single key shortcut
$app->shortcut('f5', sub {
    print "F5 pressed — refreshing\n";
    $app->refresh;
});

# Modifier combos
$app->shortcut('mod+s', sub {
    print "Save triggered (Cmd+S on macOS, Ctrl+S elsewhere)\n";
});

$app->shortcut('mod+shift+s', sub {
    print "Save As triggered\n";
});

# Prevent default browser behavior (e.g. Ctrl+P = Print)
$app->shortcut('mod+p', sub {
    print "Custom command palette opened (browser print suppressed)\n";
}, prevent_default => 1);

# Chord sequence: Ctrl+K followed by Ctrl+C
$app->shortcut('mod+k mod+c', sub {
    print "Comment selection (chord: Mod+K Mod+C)\n";
});

# Bulk registration via shortcut_map
$app->shortcut_map({
    'mod+z'       => sub { print "Undo\n" },
    'mod+shift+z' => sub { print "Redo\n" },
    'escape'      => sub { print "Escape pressed\n" },
    'f10'         => sub { print "Toggle fullscreen\n" },
});

# Disable/enable shortcuts
my $sc = $app->shortcuts;
print "Registered shortcuts:\n";
for my $b ($sc->list) {
    printf "  %s (enabled: %d, prevent_default: %d)\n",
        $b->{combo}, $b->{enabled}, $b->{prevent_default};
}

$app->set_content(q{
    <div style="font-family: sans-serif; padding: 20px;">
        <h1>Keyboard Shortcut Demo</h1>
        <p>Try these shortcuts:</p>
        <ul>
            <li><kbd>F5</kbd> — Refresh</li>
            <li><kbd>Cmd/Ctrl+S</kbd> — Save</li>
            <li><kbd>Cmd/Ctrl+Shift+S</kbd> — Save As</li>
            <li><kbd>Cmd/Ctrl+P</kbd> — Command Palette (prevents print)</li>
            <li><kbd>Cmd/Ctrl+K, Cmd/Ctrl+C</kbd> — Comment (chord)</li>
            <li><kbd>Cmd/Ctrl+Z</kbd> — Undo</li>
            <li><kbd>Cmd/Ctrl+Shift+Z</kbd> — Redo</li>
            <li><kbd>Escape</kbd> — Escape</li>
            <li><kbd>F10</kbd> — Fullscreen</li>
        </ul>
        <p>Check the terminal for output.</p>
    </div>
});

$app->run;
