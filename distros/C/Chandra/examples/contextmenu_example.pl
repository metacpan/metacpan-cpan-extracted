#!/usr/bin/env perl
#
# Example: Context Menus
#
# Right-click context menus with static items, dynamic items,
# submenus, icons, checkable items, and keyboard shortcut hints.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;

my $app = Chandra::App->new(
    title  => 'Context Menu Example',
    width  => 600,
    height => 450,
    debug  => 1,
);

# ---- Static context menu on the editor area ----

$app->context_menu('#editor', [
    { label => 'Select All',  action => sub {
        $app->eval("var e=document.getElementById('editor');var r=document.createRange();r.selectNodeContents(e);var s=window.getSelection();s.removeAllRanges();s.addRange(r);");
        log_action('Select All');
      }, shortcut => 'Ctrl+A', icon => "\x{2610}" },
    { label => 'Clear Editor', action => sub {
        $app->eval("document.getElementById('editor').textContent='';");
        log_action('Clear Editor');
      }, icon => "\x{1f5d1}" },
    { separator => 1 },
    { label => 'Word Wrap',  checkable => 1, checked => 1,
      action => sub {
        my $on = $_[0] ? 'pre-wrap' : 'pre';
        $app->eval("document.getElementById('editor').style.whiteSpace='$on';");
        log_action("Word Wrap: " . ($_[0] ? 'ON' : 'OFF'));
      } },
    { separator => 1 },
    { label => 'Theme', submenu => [
        { label => 'Light',  action => sub {
            $app->eval("var e=document.getElementById('editor');e.style.background='#fff';e.style.color='#333';");
            log_action('Theme: Light');
          } },
        { label => 'Dark',   action => sub {
            $app->eval("var e=document.getElementById('editor');e.style.background='#1e1e1e';e.style.color='#d4d4d4';");
            log_action('Theme: Dark');
          } },
        { label => 'Sepia',  action => sub {
            $app->eval("var e=document.getElementById('editor');e.style.background='#f4ecd8';e.style.color='#5b4636';");
            log_action('Theme: Sepia');
          } },
    ]},
    { label => 'Insert Snippet', submenu => [
        { label => 'Hello World', action => sub {
            $app->eval("var e=document.getElementById('editor');e.textContent+='\\n# Hello World\\nprint \"Hello, World!\\\\n\";\\n';");
            log_action('Insert: Hello World');
          } },
        { label => 'Read File', action => sub {
            $app->eval('var e=document.getElementById("editor");e.textContent+="\nopen my $fh, \"<\", $file or die $!;\nmy $data = do { local $/; <$fh> };\nclose $fh;\n";');
            log_action('Insert: Read File');
          } },
    ]},
    { label => 'Increase Font', action => sub {
        $app->eval("var e=document.getElementById('editor');var s=parseFloat(getComputedStyle(e).fontSize);e.style.fontSize=(s+2)+'px';");
        log_action('Increase Font');
      }, shortcut => 'Ctrl+=' },
    { label => 'Decrease Font', action => sub {
        $app->eval("var e=document.getElementById('editor');var s=parseFloat(getComputedStyle(e).fontSize);if(s>8)e.style.fontSize=(s-2)+'px';");
        log_action('Decrease Font');
      }, shortcut => 'Ctrl+-' },
]);

# ---- Dynamic context menu on list items ----

$app->context_menu('.list-item', sub {
    my ($target) = @_;
    my $id = $target->{id} || 'unknown';
    my $name = $id;
    $name =~ s/^file-//;
    return [
        { label => "Open $name", icon => "\x{1f4c4}", action => sub {
            $app->eval("document.getElementById('editor').textContent='# Contents of $name\\n# (loaded from sidebar)\\nprint \"Editing $name\\\\n\";\\n';");
            $app->eval("document.querySelectorAll('.list-item').forEach(function(el){el.style.background='';});document.getElementById('$id').style.background='#b8d4f0';");
            log_action("Opened $name");
          } },
        { label => "Rename $name", icon => "\x{270f}", action => sub {
            $app->eval("var el=document.getElementById('$id');el.textContent='renamed-'+el.textContent;");
            log_action("Renamed $name");
          } },
        { label => "Duplicate $name", icon => "\x{2398}", action => sub {
            $app->eval("var el=document.getElementById('$id');var cl=el.cloneNode(true);cl.id='';cl.textContent=el.textContent+' (copy)';el.parentNode.insertBefore(cl,el.nextSibling);");
            log_action("Duplicated $name");
          } },
        { separator => 1 },
        { label => "Delete $name", icon => "\x{1f5d1}", action => sub {
            $app->eval("var el=document.getElementById('$id');if(el)el.remove();");
            log_action("Deleted $name");
          } },
    ];
});

sub log_action {
    my ($msg) = @_;
    $app->eval(
        "document.getElementById('log').innerHTML += "
        . "'<div class=\"log-entry\">" . $msg . "</div>';"
        . "document.getElementById('log').scrollTop = "
        . "document.getElementById('log').scrollHeight;"
    );
}

$app->set_content(<<'HTML');
<!DOCTYPE html>
<html>
<head>
<style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
           margin: 0; display: flex; flex-direction: column; height: 100vh;
           background: #f5f5f5; color: #333; }
    .header { padding: 12px 16px; background: #2c3e50; color: white;
              font-size: 14px; font-weight: 600; }
    .main { display: flex; flex: 1; overflow: hidden; }
    .sidebar { width: 200px; background: #ecf0f1; border-right: 1px solid #ddd;
               padding: 8px 0; overflow-y: auto; }
    .list-item { padding: 8px 16px; cursor: pointer; font-size: 13px; }
    .list-item:hover { background: #dfe6e9; }
    #editor { flex: 1; padding: 16px; font-family: monospace; font-size: 13px;
              white-space: pre-wrap; background: #fff; overflow-y: auto;
              line-height: 1.6; min-height: 200px; }
    #log { height: 120px; overflow-y: auto; background: #2d2d2d; color: #0f0;
           font-family: monospace; font-size: 12px; padding: 8px; border-top: 2px solid #444; }
    .log-entry { padding: 2px 0; }
    .hint { color: #888; font-size: 12px; padding: 8px 16px; background: #fafafa;
            border-top: 1px solid #eee; }
</style>
</head>
<body>
    <div class="header">Context Menu Example</div>
    <div class="main">
        <div class="sidebar">
            <div class="list-item" id="file-readme">README.md</div>
            <div class="list-item" id="file-main">main.pl</div>
            <div class="list-item" id="file-config">config.yml</div>
            <div class="list-item" id="file-test">test.t</div>
            <div class="list-item" id="file-lib">lib/App.pm</div>
        </div>
        <div id="editor">use strict;
use warnings;

sub hello {
    my ($name) = @_;
    print "Hello, $name!\n";
}

hello("World");
</div>
    </div>
    <div class="hint">Right-click on the editor or file list items to see context menus</div>
    <div id="log"></div>
</body>
</html>
HTML

$app->run;
