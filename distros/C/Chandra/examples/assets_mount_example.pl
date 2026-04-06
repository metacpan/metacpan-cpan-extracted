#!/usr/bin/env perl
#
# Example: Serving assets via protocol mount
#
# Demonstrates mounting an assets directory so that CSS, JS, and images
# are served via a custom protocol (e.g. app://css/style.css).
# The mount() call registers a protocol handler, and the injected JS
# transparently intercepts <link>, <script>, <img>, and fetch() calls.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Path qw(mkpath rmtree);
use Chandra::App;

# ---- Setup: create a sample assets directory ----

my $asset_dir = '/tmp/chandra_mount_example';
rmtree($asset_dir) if -d $asset_dir;
mkpath("$asset_dir/css");
mkpath("$asset_dir/js");

_write("$asset_dir/css/style.css", <<'CSS');
body {
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    margin: 0; padding: 2em;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: #fff;
    min-height: 100vh;
}
h1 { margin-bottom: 0.5em; }
.card {
    background: rgba(255,255,255,0.15);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 1.5em;
    margin: 1em 0;
    border: 1px solid rgba(255,255,255,0.2);
}
button {
    background: #fff; color: #764ba2;
    border: none; border-radius: 6px;
    padding: 0.6em 1.2em; cursor: pointer;
    font-weight: bold; font-size: 1em;
}
button:hover { opacity: 0.9; }
#status { color: #a5d6a7; font-weight: bold; }
CSS

_write("$asset_dir/js/main.js", <<'JS');
(function init() {
    // Protocol-loaded scripts arrive after DOMContentLoaded,
    // so run immediately when the DOM is already ready.
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', run);
    } else {
        run();
    }
    function run() {
        document.getElementById('status').textContent = 'Assets loaded via protocol!';
        document.getElementById('greet-btn').addEventListener('click', async function() {
            var name = document.getElementById('name-input').value || 'World';
            var result = await window.chandra.invoke('greet', [name]);
            document.getElementById('greeting').textContent = result;
        });
    }
})();
JS

# ---- Create the app ----

my $app = Chandra::App->new(
    title  => 'Assets Mount Example',
    width  => 500,
    height => 400,
    debug  => 1,
);

# ---- Mount assets ----
# This registers a custom protocol handler so the webview can load
# files from $asset_dir using the "app" scheme: app://css/style.css
# The injected JS transparently intercepts <link>, <script>, <img>,
# fetch(), and <a> clicks for the "app://" scheme.

my $assets = $app->assets($asset_dir, prefix => 'app');
$assets->mount($app);

# ---- Bind a Perl function ----

$app->bind('greet', sub {
    my ($name) = @_;
    return "Hello, $name! Greetings from Perl.";
});

# ---- Set content referencing mounted assets ----

$app->set_content(<<'HTML');
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <link rel="stylesheet" data-href="app://css/style.css">
</head>
<body>
    <h1>Assets Mount Example</h1>
    <p>Status: <span id="status">Loading...</span></p>

    <div class="card">
        <p>CSS and JS are served from disk via the <code>app://</code> protocol.</p>
        <p>No inlining needed &mdash; the webview fetches them like a real browser.</p>
    </div>

    <div class="card">
        <input id="name-input" type="text" placeholder="Enter your name">
        <button id="greet-btn">Greet</button>
        <p id="greeting"></p>
    </div>

    <script data-src="app://js/main.js"></script>
</body>
</html>
HTML

$app->run;

# Cleanup
rmtree($asset_dir);

sub _write {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}
