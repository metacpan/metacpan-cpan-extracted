#!/usr/bin/env perl
#
# Example: Bridge Extension — Task Manager
#
# Demonstrates Chandra::Bridge::Extension with both inline JS
# registration and register_file, plus App->extend_bridge.
# A small task-manager UI that uses custom JS utilities injected
# into window.chandra.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempfile);
use Chandra::App;
use Chandra::Bridge::Extension;

# ── 1. Register an inline extension: "utils" ────────────────────────
Chandra::Bridge::Extension->register('utils', <<'JS');
    return {
        id: 0,
        uid: function() { return ++this.id; },
        timestamp: function() {
            var d = new Date();
            return d.getHours() + ':' +
                   ('0' + d.getMinutes()).slice(-2) + ':' +
                   ('0' + d.getSeconds()).slice(-2);
        },
        escapeHtml: function(s) {
            var el = document.createElement('span');
            el.textContent = s;
            return el.innerHTML;
        }
    };
JS

# ── 2. Register from a file: "toast" (depends on utils) ─────────────
my ($fh, $toast_file) = tempfile(SUFFIX => '.js', UNLINK => 1);
print $fh <<'TOAST_JS';
    var utils = window.chandra.utils;
    return {
        show: function(msg, type) {
            type = type || 'info';
            var el = document.createElement('div');
            el.className = 'toast toast-' + type;
            el.textContent = '[' + utils.timestamp() + '] ' + msg;
            document.getElementById('toasts').appendChild(el);
            setTimeout(function() { el.remove(); }, 4000);
        }
    };
TOAST_JS
close $fh;

Chandra::Bridge::Extension->register_file('toast', $toast_file,
    depends => ['utils']);

# ── 3. Create the app and use extend_bridge for "taskui" ────────────
my $app = Chandra::App->new(
    title  => 'Task Manager',
    width  => 520,
    height => 620,
    debug  => 1,
);

$app->extend_bridge('taskui', <<'JS', depends => ['utils', 'toast']);
    var utils = window.chandra.utils;
    var toast = window.chandra.toast;
    return {
        addTask: function(text) {
            if (!text) return;
            var id = utils.uid();
            var safe = utils.escapeHtml(text);
            var li = document.createElement('li');
            li.id = 'task-' + id;
            li.innerHTML =
                '<span class="text">' + safe + '</span>' +
                '<span class="time">' + utils.timestamp() + '</span>' +
                '<button onclick="completeTask(' + id + ')">Done</button>';
            document.getElementById('tasks').appendChild(li);
            toast.show('Added: ' + text, 'info');
            /* also tell Perl */
            window.chandra.invoke('task_added', [id, text]);
        },
        completeTask: function(id) {
            var el = document.getElementById('task-' + id);
            if (!el) return;
            el.classList.add('done');
            el.querySelector('button').disabled = true;
            toast.show('Completed task #' + id, 'success');
            window.chandra.invoke('task_done', [id]);
        }
    };
JS

# ── 4. Perl-side callbacks ──────────────────────────────────────────
my %tasks;

$app->bind('task_added', sub {
    my ($id, $text) = @_;
    $tasks{$id} = { text => $text, done => 0 };
    printf "[Perl] task #%d added: %s  (total: %d)\n", $id, $text, scalar keys %tasks;
    return 1;
});

$app->bind('task_done', sub {
    my ($id) = @_;
    if ($tasks{$id}) {
        $tasks{$id}{done} = 1;
        printf "[Perl] task #%d completed\n", $id;
    }
    return 1;
});

$app->bind('get_stats', sub {
    my $total = scalar keys %tasks;
    my $done  = grep { $_->{done} } values %tasks;
    return "$done / $total completed";
});

# ── 5. HTML content ─────────────────────────────────────────────────
$app->set_content(<<'HTML');
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
        color: #e0e0e0;
        min-height: 100vh;
        padding: 20px;
    }
    h1 { text-align: center; margin-bottom: 16px; font-size: 22px; color: #e94560; }
    .input-row {
        display: flex; gap: 8px; margin-bottom: 16px;
    }
    .input-row input {
        flex: 1; padding: 10px 14px; border-radius: 8px; border: 1px solid #333;
        background: #1a1a2e; color: #fff; font-size: 14px; outline: none;
    }
    .input-row input:focus { border-color: #e94560; }
    .input-row button, #stats-btn {
        padding: 10px 18px; border-radius: 8px; border: none; cursor: pointer;
        background: #e94560; color: #fff; font-size: 14px; font-weight: 600;
        transition: background 0.2s;
    }
    .input-row button:hover, #stats-btn:hover { background: #c73652; }
    ul#tasks { list-style: none; }
    ul#tasks li {
        display: flex; align-items: center; gap: 8px;
        padding: 10px 14px; margin-bottom: 6px; border-radius: 8px;
        background: rgba(255,255,255,0.06); transition: opacity 0.3s;
    }
    ul#tasks li .text { flex: 1; }
    ul#tasks li .time { font-size: 11px; color: #888; }
    ul#tasks li button {
        padding: 4px 12px; border-radius: 6px; border: none;
        background: #2ecc71; color: #fff; cursor: pointer; font-size: 12px;
    }
    ul#tasks li button:disabled { background: #555; cursor: default; }
    ul#tasks li.done .text { text-decoration: line-through; color: #666; }
    #toasts {
        position: fixed; bottom: 12px; right: 12px; z-index: 999;
        display: flex; flex-direction: column; gap: 6px;
    }
    .toast {
        padding: 8px 16px; border-radius: 8px; font-size: 13px;
        animation: fadeIn 0.3s ease;
    }
    .toast-info    { background: #2980b9; color: #fff; }
    .toast-success { background: #27ae60; color: #fff; }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; } }
    #stats { text-align: center; margin-top: 14px; font-size: 13px; color: #888; }
    #stats-btn { margin-top: 10px; display: block; margin-left: auto; margin-right: auto; }
</style>
</head>
<body>
    <h1>Task Manager</h1>
    <div class="input-row">
        <input id="inp" placeholder="What needs doing?" onkeydown="if(event.key==='Enter') addTask()">
        <button onclick="addTask()">Add</button>
    </div>
    <ul id="tasks"></ul>
    <div id="stats"></div>
    <button id="stats-btn" onclick="showStats()">Show Stats</button>
    <div id="toasts"></div>

    <script>
        function addTask() {
            var inp = document.getElementById('inp');
            window.chandra.taskui.addTask(inp.value);
            inp.value = '';
            inp.focus();
        }
        function completeTask(id) {
            window.chandra.taskui.completeTask(id);
        }
        function showStats() {
            window.chandra.invoke('get_stats', []).then(function(s) {
                document.getElementById('stats').textContent = s;
            });
        }
    </script>
</body>
</html>
HTML

print "Starting task manager…\n";
print "Extensions loaded: ", join(', ', Chandra::Bridge::Extension->list), "\n";
$app->run;
print "Done.\n";

=head1 NAME

Bridge Extension Example - Task Manager with inline and file-based JS extensions

=head1 DESCRIPTION

Demonstrates all three ways to register bridge extensions:

=over 4

=item 1. B<Inline> via C<< Chandra::Bridge::Extension->register >>

The C<utils> extension provides helper functions (uid, timestamp, escapeHtml).

=item 2. B<From file> via C<< Chandra::Bridge::Extension->register_file >>

The C<toast> extension (depends on C<utils>) is loaded from a temporary JS
file and provides notification toasts.

=item 3. B<Via App> using C<< $app->extend_bridge >>

The C<taskui> extension (depends on C<utils> and C<toast>) provides the
task-list DOM manipulation, using both other extensions.

=back

Extensions are injected into C<window.chandra> in dependency order and
persist across page reloads.

=cut
