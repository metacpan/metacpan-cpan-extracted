#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use Chandra::App;
use Chandra::Modal;
use Chandra::Toast;

my $app = Chandra::App->new(
    title  => 'Modal Demo',
    width  => 600,
    height => 400,
    debug => 1
);

$app->theme('dark');

# ── Confirm dialog ────────────────────────────────────────

$app->bind('show_confirm', sub {
    Chandra::Modal->confirm($app,
        title   => 'Delete Project',
        message => 'This will permanently delete the project and all its files. This action cannot be undone.',
        on_ok   => sub {
            $app->toast('Project deleted', type => 'success');
        },
    );
});

# ── Prompt dialog ─────────────────────────────────────────

$app->bind('show_prompt', sub {
    Chandra::Modal->prompt($app,
        title     => 'Rename File',
        label     => 'New filename:',
        value     => 'document.txt',
        on_submit => sub {
            my ($value) = @_;
            $app->toast("Renamed to: $value", type => 'info');
        },
    );
});

# ── Custom modal ──────────────────────────────────────────

$app->bind('show_custom', sub {
    Chandra::Modal->show($app,
        title   => 'About This App',
        width   => 450,
        content => '<div style="text-align:center;">'
                 . '<h2 style="margin:0 0 8px;">Modal Demo</h2>'
                 . '<p style="color:var(--chandra-text-muted);">Version 1.0.0</p>'
                 . '<p>Built with <strong>Chandra</strong> &mdash; '
                 . 'a Perl desktop GUI framework.</p>'
                 . '<hr>'
                 . '<p style="font-size:0.85em;color:var(--chandra-text-muted);">'
                 . 'Modals, toasts, themes, tables, and components &mdash; all in XS.</p>'
                 . '</div>',
        buttons => [
            { label => 'Close', class => 'primary', action => 'close' },
        ],
    );
});

# ── Multi-button modal ────────────────────────────────────

$app->bind('show_multi', sub {
    Chandra::Modal->show($app,
        title   => 'Save Changes?',
        message => 'You have unsaved changes. What would you like to do?',
        width   => 420,
        buttons => [
            { label => 'Discard', class => 'danger', action => sub {
                $app->toast('Changes discarded', type => 'warning');
            }},
            { label => 'Cancel', class => 'secondary', action => 'close' },
            { label => 'Save', class => 'primary', action => sub {
                $app->toast('Changes saved', type => 'success');
            }},
        ],
    );
});

# ── Layout ────────────────────────────────────────────────

$app->set_content(<<'HTML');
<div style="padding:40px; text-align:center;">
    <h1>Modal Dialogs</h1>
    <p style="color:var(--chandra-text-muted); margin-bottom:32px;">
        Click a button to see each modal type.
    </p>
    <div style="display:flex; flex-direction:column; gap:12px; max-width:300px; margin:0 auto;">
        <button class="chandra-btn-primary" onclick="window.chandra.invoke('show_confirm', [])">
            Confirm Dialog
        </button>
        <button class="chandra-btn-primary" onclick="window.chandra.invoke('show_prompt', [])">
            Prompt Dialog
        </button>
        <button class="chandra-btn" onclick="window.chandra.invoke('show_custom', [])">
            Custom Modal
        </button>
        <button class="chandra-btn" onclick="window.chandra.invoke('show_multi', [])">
            Multi-Button Modal
        </button>
    </div>
</div>
HTML

$app->run;
