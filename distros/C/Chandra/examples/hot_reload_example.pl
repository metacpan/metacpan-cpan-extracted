#!/usr/bin/env perl
#
# Example: Hot Reload
#
# Demonstrates file watching with automatic content refresh.
# Edit the watched file while the app is running to see changes
# reflected instantly.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;

my $content_file = "$FindBin::Bin/hot_reload_content.html";

# Create an initial content file if it doesn't exist
unless (-f $content_file) {
    open my $fh, '>', $content_file or die "Cannot create $content_file: $!";
    print $fh <<'HTML';
<div style="padding:20px;font-family:sans-serif;">
    <h1>Hot Reload Demo</h1>
    <p>Edit hot_reload_content.html and save — this page updates automatically!</p>
</div>
HTML
    close $fh;
}

sub load_content {
    open my $fh, '<', $content_file or return '<h1>Error loading content</h1>';
    local $/;
    my $html = <$fh>;
    close $fh;
    return $html;
}

my $app = Chandra::App->new(
    title  => 'Hot Reload Demo',
    width  => 600,
    height => 400,
    debug  => 1,
);

$app->set_content(load_content());

# Watch the content file and refresh on change
$app->watch($content_file, sub {
    my ($changed) = @_;
    print "[HotReload] Changed: @$changed\n";
    $app->set_content(load_content());
    $app->refresh;
});

$app->devtools->log("Watching: $content_file");

$app->run;
