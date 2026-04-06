#!/usr/bin/env perl
use strict;
use warnings;
use File::Path qw(mkpath rmtree);

use Chandra::Assets;

# ---- Setup: create a sample assets directory ----

my $asset_dir = '/tmp/chandra_assets_example';
rmtree($asset_dir) if -d $asset_dir;
mkpath("$asset_dir/css");
mkpath("$asset_dir/js");
mkpath("$asset_dir/images");

_write("$asset_dir/css/style.css", <<'CSS');
body {
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    margin: 2em;
    background: #f5f5f5;
    color: #333;
}
h1 { color: #0066cc; }
.card {
    background: white;
    border-radius: 8px;
    padding: 1.5em;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    margin: 1em 0;
}
CSS

_write("$asset_dir/css/reset.css", <<'CSS');
*, *::before, *::after { box-sizing: border-box; }
body, h1, h2, p { margin: 0; padding: 0; }
CSS

_write("$asset_dir/js/main.js", <<'JS');
document.addEventListener('DOMContentLoaded', function() {
    console.log('App ready');
    document.getElementById('status').textContent = 'Loaded!';
});
JS

_write("$asset_dir/js/utils.js", <<'JS');
function formatDate(d) { return d.toISOString().split('T')[0]; }
function capitalize(s) { return s.charAt(0).toUpperCase() + s.slice(1); }
JS

sub _write {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

# ---- Example 1: Standalone asset management ----

print "=== Standalone Chandra::Assets ===\n\n";

my $assets = Chandra::Assets->new(
    root   => $asset_dir,
    prefix => 'app',
);

printf "Root:   %s\n", $assets->root;
printf "Prefix: %s\n", $assets->prefix;

# MIME detection
printf "\nMIME types:\n";
for my $file ('style.css', 'main.js', 'logo.png', 'font.woff2', 'data.json') {
    printf "  %-15s => %s\n", $file, $assets->mime_type($file);
}

# Read a file
print "\nCSS content:\n";
my $css = $assets->read('css/style.css');
printf "  %d bytes\n", length($css);

# Check existence
printf "\nExists checks:\n";
for my $f ('css/style.css', 'js/main.js', 'missing.txt') {
    printf "  %-20s => %s\n", $f, $assets->exists($f) ? 'yes' : 'no';
}

# List directory
print "\nAsset listing:\n";
my @files = $assets->list;
printf "  %s\n", $_ for sort @files;

# ---- Example 2: Inline assets ----

print "\n=== Inline Assets ===\n\n";

my $style_tag = $assets->inline_css('css/style.css');
printf "inline_css: %d chars, starts with: %.40s...\n",
    length($style_tag), $style_tag;

my $script_tag = $assets->inline_js('js/main.js');
printf "inline_js:  %d chars, starts with: %.40s...\n",
    length($script_tag), $script_tag;

# ---- Example 3: Bundle multiple files ----

print "\n=== Bundle ===\n\n";

my $bundle = $assets->bundle(
    css => ['css/reset.css', 'css/style.css'],
    js  => ['js/utils.js', 'js/main.js'],
);

printf "Bundled CSS: %d chars\n", length($bundle->{css});
printf "Bundled JS:  %d chars\n", length($bundle->{js});

# ---- Example 4: Integration with Chandra::App ----

print "\n=== Integration Pattern ===\n\n";
print <<'EXAMPLE';
# In a real Chandra app:
#
#   use Chandra::App;
#
#   my $app = Chandra::App->new(title => 'My App');
#
#   # Mount assets directory (creates protocol handler)
#   my $assets = $app->assets('assets/', prefix => 'app');
#   $assets->mount($app);
#
#   # Serve files via protocol (use data-href/data-src to
#   # avoid "unsupported URL" console warnings):
#   #   <link rel="stylesheet" data-href="app://css/style.css">
#   #   <script data-src="app://js/main.js"></script>
#
#   # Or inline everything for single-file distribution:
#   $app->set_content(
#       $assets->inline_css('css/style.css') .
#       '<div id="app">Hello</div>' .
#       $assets->inline_js('js/main.js')
#   );
#
#   $app->run;
EXAMPLE

# Cleanup
rmtree($asset_dir);
print "Done.\n";
