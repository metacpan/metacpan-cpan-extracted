#!/usr/bin/env perl
#
# Example: Drag and Drop
#
# Drop files from Finder/Explorer into the app window.
# Also demonstrates intra-app drag between columns.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;

my $app = Chandra::App->new(
    title  => 'Drag & Drop Example',
    width  => 600,
    height => 500,
    debug  => 1,
);

# ---- Global file drop handler ----

$app->on_file_drop(sub {
    my ($files) = @_;
    my $count = scalar @$files;
    my $names = join ', ', map { (split m{/}, $_)[-1] } @$files;
    $app->eval(
        "document.getElementById('drop-log').innerHTML += "
        . "'<div class=\"entry\">Dropped $count file(s): $names</div>';"
    );
});

# ---- Zone-specific handler ----

$app->drop_zone('#upload-zone', sub {
    my ($files, $target) = @_;
    my $count = scalar @$files;
    $app->eval(
        "document.getElementById('upload-status').textContent = "
        . "'Received $count file(s) in upload zone';"
    );
});

# ---- Advanced: intra-app drag ----

my $dd = $app->drag_drop;

$dd->make_draggable('.draggable', data_from => 'data-item');

$dd->on_internal_drop(sub {
    my ($data, $source, $target) = @_;
    my $src_id = ref $source ? ($source->{id} || '?') : '?';
    my $tgt_id = ref $target ? ($target->{id} || '?') : '?';
    $app->eval(
        "document.getElementById('drag-log').innerHTML += "
        . "'<div class=\"entry\">Moved \\\"$data\\\" from $src_id to $tgt_id</div>';"
    );
});

$dd->on_drag_enter(sub {
    my ($target) = @_;
    return 'drag-over';
});

$dd->on_drag_leave(sub {
    my ($target) = @_;
    my $id = ref $target ? ($target->{id} || '') : '';
    $app->eval("var _el=document.getElementById('$id');if(_el)_el.classList.remove('drag-over');") if $id;
});

# ---- Content ----

$app->set_content(<<'HTML');
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    body {
        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
        margin: 0; padding: 20px;
        background: #1a1a2e; color: #e0e0e0;
    }
    h1 { color: #e94560; margin-top: 0; }
    h2 { color: #0f3460; background: #e94560; display: inline-block;
         padding: 4px 12px; border-radius: 4px; font-size: 14px; }

    .drop-zone {
        border: 2px dashed #555;
        border-radius: 12px;
        padding: 20px;
        text-align: center;
        margin: 12px 0;
        transition: all 0.2s;
    }
    .drop-zone.drag-over {
        border-color: #e94560;
        background: rgba(233, 69, 96, 0.1);
    }

    #upload-zone { min-height: 80px; }
    #upload-status { color: #4ecca3; margin-top: 8px; }

    .columns { display: flex; gap: 16px; margin-top: 12px; }
    .column {
        flex: 1; background: #16213e; border-radius: 8px;
        padding: 12px; min-height: 100px;
    }
    .draggable {
        background: #0f3460; padding: 8px 12px; border-radius: 6px;
        margin: 6px 0; cursor: grab; user-select: none;
    }
    .draggable:active { cursor: grabbing; }

    .log { max-height: 120px; overflow-y: auto; margin-top: 8px; }
    .entry { padding: 4px 0; border-bottom: 1px solid #333; font-size: 13px; }
</style>
</head>
<body>
    <h1>Drag &amp; Drop</h1>

    <h2>File Drop</h2>
    <div id="upload-zone" class="drop-zone">
        Drop files here (zone-specific handler)
        <div id="upload-status"></div>
    </div>
    <div class="log" id="drop-log"></div>

    <h2>Intra-App Drag</h2>
    <div class="columns">
        <div class="column" id="col-todo">
            <strong>Todo</strong>
            <div class="draggable" id="task-1" data-item="Buy groceries">Buy groceries</div>
            <div class="draggable" id="task-2" data-item="Write tests">Write tests</div>
            <div class="draggable" id="task-3" data-item="Deploy app">Deploy app</div>
        </div>
        <div class="column" id="col-done">
            <strong>Done</strong>
        </div>
    </div>
    <div class="log" id="drag-log"></div>
</body>
</html>
HTML

$app->run;
