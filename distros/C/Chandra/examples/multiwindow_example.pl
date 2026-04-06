#!/usr/bin/env perl
use strict;
use warnings;
use Chandra::App;
use Cpanel::JSON::XS qw(encode_json);
use List::Util qw(max);

# -----------------------------------------------------------------------
# Multi-window todo list application
#
# Layout:
#   Main window  — displays the todo list and an "Add" button
#   Add dialog   — modal form to enter a new todo item
#   Settings     — non-modal window for app preferences
# -----------------------------------------------------------------------

my @todos    = ();    # shared in-process state
my $filter   = 'all'; # 'all' | 'active' | 'done'
my $settings_win;
my $add_win;

# -----------------------------------------------------------------------
# Main application window
# -----------------------------------------------------------------------

my $app = Chandra::App->new(
    title  => 'Todos',
    width  => 600,
    height => 500,
    debug => 1,
);

# Persist the window size via Chandra::Store
my $store = $app->store;
my $saved_w = $store->get('window.width',  600);
my $saved_h = $store->get('window.height', 500);

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

sub render_todos {
    my $theme = $store->get('theme', 'light');
    my $is_dark = $theme eq 'dark';
    
    my @visible = $filter eq 'all'    ? @todos
                : $filter eq 'active' ? grep { !$_->{done} } @todos
                :                       grep {  $_->{done} } @todos;

    my $done_color = $is_dark ? '#666' : '#888';
    my $items = join '', map {
        my $id      = $_->{id};
        my $text    = $_->{text};
        my $checked = $_->{done} ? 'checked' : '';
        my $strike  = $_->{done} ? qq(style="text-decoration:line-through;color:$done_color") : '';
        qq(<li>
          <input type="checkbox" $checked
            onchange="window.chandra.invoke('toggle',[$id])">
          <span $strike>$text</span>
          <button onclick="window.chandra.invoke('remove',[$id])">✕</button>
        </li>)
    } @visible;

    my $remaining = scalar grep { !$_->{done} } @todos;
    my $total     = scalar @todos;
    
    my $all_active    = $filter eq 'all'    ? 'active' : '';
    my $active_active = $filter eq 'active' ? 'active' : '';
    my $done_active   = $filter eq 'done'   ? 'active' : '';
    
    # Dark mode colors
    my $bg          = $is_dark ? '#1a1a2e' : '#fafafa';
    my $toolbar_bg  = $is_dark ? '#16213e' : '#fff';
    my $toolbar_bdr = $is_dark ? '#0f3460' : '#eee';
    my $btn_bg      = $is_dark ? '#0f3460' : '#ecf0f1';
    my $btn_fg      = $is_dark ? '#eee'    : '#333';
    my $li_border   = $is_dark ? '#0f3460' : '#f0f0f0';
    my $li_fg       = $is_dark ? '#eee'    : 'inherit';
    my $footer_fg   = $is_dark ? '#888'    : '#888';
    my $del_btn     = $is_dark ? '#555'    : '#ccc';

    return qq(
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: system-ui, sans-serif; margin: 0; background: $bg; color: $li_fg; }
  h1   { background: #e74c3c; color: #fff; margin: 0; padding: 16px 20px; font-size: 1.4em; }
  .toolbar { display:flex; gap:8px; padding:12px 20px; background:$toolbar_bg; border-bottom:1px solid $toolbar_bdr; }
  button   { cursor:pointer; border:none; border-radius:4px; padding:6px 12px; font-size:.9em; }
  .btn-add { background:#e74c3c; color:#fff; }
  .btn-settings { background:$btn_bg; color:$btn_fg; margin-left:auto; }
  .filters { display:flex; gap:4px; }
  .filters button { background:$btn_bg; color:$btn_fg; }
  .filters button.active { background:#3498db; color:#fff; }
  ul   { list-style:none; margin:0; padding:0 20px; }
  li   { display:flex; align-items:center; gap:8px; padding:10px 0;
         border-bottom:1px solid $li_border; }
  li input[type=checkbox] { width:18px; height:18px; cursor:pointer; }
  li span { flex:1; }
  li button { background:transparent; color:$del_btn; font-size:1.1em; padding:2px 6px; }
  li button:hover { color:#e74c3c; }
  .footer { padding:12px 20px; color:$footer_fg; font-size:.85em; }
</style>
</head>
<body>
<h1>Todos</h1>
<div class="toolbar">
  <button class="btn-add"
    onclick="window.chandra.invoke('open_add', [])">+ Add Todo</button>
  <div class="filters">
    <button class="$all_active"
      onclick="window.chandra.invoke('set_filter',['all'])">All</button>
    <button class="$active_active"
      onclick="window.chandra.invoke('set_filter',['active'])">Active</button>
    <button class="$done_active"
      onclick="window.chandra.invoke('set_filter',['done'])">Done</button>
  </div>
  <button class="btn-settings"
    onclick="window.chandra.invoke('open_settings',[])">⚙ Settings</button>
</div>
<ul>$items</ul>
<div class="footer">$remaining of $total item(s) remaining</div>
</body>
</html>
);
}

sub refresh_main {
    $app->set_content(render_todos());
    $app->refresh();
}

# -----------------------------------------------------------------------
# Main window bindings
# -----------------------------------------------------------------------

my $next_id = 1;

$app->bind('toggle', sub {
    my ($id) = @_;
    for my $t (@todos) {
        $t->{done} = !$t->{done} if $t->{id} == $id;
    }
    $store->set('todos', \@todos);
    refresh_main();
    return undef;
});

$app->bind('remove', sub {
    my ($id) = @_;
    @todos = grep { $_->{id} != $id } @todos;
    $store->set('todos', \@todos);
    refresh_main();
    return undef;
});

$app->bind('set_filter', sub {
    my ($f) = @_;
    $filter = $f;
    refresh_main();
    return undef;
});

# -----------------------------------------------------------------------
# Add-todo dialog
# -----------------------------------------------------------------------

sub add_html {
    my $theme = $store->get('theme', 'light');
    my $is_dark = $theme eq 'dark';
    
    my $bg       = $is_dark ? '#1a1a2e' : '#fff';
    my $fg       = $is_dark ? '#eee'    : '#333';
    my $input_bg = $is_dark ? '#16213e' : '#fff';
    my $input_bd = $is_dark ? '#0f3460' : '#ccc';
    my $btn_bg   = $is_dark ? '#0f3460' : '#ecf0f1';
    my $btn_fg   = $is_dark ? '#eee'    : '#333';
    
    return qq(
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family:system-ui,sans-serif; margin:0; padding:20px; background:$bg; color:$fg; }
  h2   { margin-top:0; font-size:1.1em; }
  input[type=text] { width:100%; box-sizing:border-box; padding:8px; font-size:1em;
                     border:1px solid $input_bd; border-radius:4px; background:$input_bg; color:$fg; }
  .buttons { display:flex; gap:8px; margin-top:12px; justify-content:flex-end; }
  button { border:none; border-radius:4px; padding:8px 16px; cursor:pointer; font-size:.9em; }
  .ok     { background:#e74c3c; color:#fff; }
  .cancel { background:$btn_bg; color:$btn_fg; }
</style>
</head>
<body>
<h2>New Todo</h2>
<input type="text" id="txt" placeholder="What needs to be done?"
  onkeydown="if(event.key==='Enter') document.getElementById('ok').click()">
<div class="buttons">
  <button class="cancel"
    onclick="window.chandra.invoke('add_cancel',[])">Cancel</button>
  <button id="ok" class="ok"
    onclick="window.chandra.invoke('add_ok',[document.getElementById('txt').value])">Add</button>
</div>
<script>document.getElementById('txt').focus();</script>
</body>
</html>
);
}

$app->bind('open_add', sub {
    if ($add_win && !$add_win->is_closed) {
        $add_win->focus;
        return undef;
    }
    $add_win = $app->open_window(
        title   => 'Add Todo',
        width   => 360,
        height  => 160,
        modal   => 1,
        content => add_html(),
        debug   => 1,
    );
    $add_win->on_close(sub { 1 });
    return undef;
});

$app->bind('add_ok', sub {
    my ($text) = @_;
    $text //= '';
    $text =~ s/^\s+|\s+$//g;
    if (length $text) {
        push @todos, { id => $next_id++, text => $text, done => 0 };
        $store->set('todos', \@todos);
        refresh_main();
    }
    $add_win->close if $add_win && !$add_win->is_closed;
    return undef;
});

$app->bind('add_cancel', sub {
    $add_win->close if $add_win && !$add_win->is_closed;
    return undef;
});

# -----------------------------------------------------------------------
# Settings window
# -----------------------------------------------------------------------

sub settings_html {
    my $theme = $store->get('theme', 'light');
    my $is_dark = $theme eq 'dark';
    my $checked = $is_dark ? 'checked' : '';
    
    my $bg     = $is_dark ? '#1a1a2e' : '#fff';
    my $fg     = $is_dark ? '#eee'    : '#333';
    
    return qq(
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family:system-ui,sans-serif; margin:0; padding:20px; background:$bg; color:$fg; }
  h2   { margin-top:0; font-size:1.1em; }
  label { display:flex; align-items:center; gap:8px; margin:10px 0; }
  button { border:none; border-radius:4px; padding:8px 16px; cursor:pointer;
           background:#e74c3c; color:#fff; margin-top:12px; font-size:.9em; }
</style>
</head>
<body>
<h2>Settings</h2>
<label>
  <input type="checkbox" id="dark" $checked
    onchange="window.chandra.invoke('set_theme',[this.checked?'dark':'light'])">
  Dark theme
</label>
<button onclick="window.chandra.invoke('clear_done',[])">Clear completed todos</button>
</body>
</html>
);
}

$app->bind('open_settings', sub {
    if ($settings_win && !$settings_win->is_closed) {
        $settings_win->show;
        $settings_win->focus;
        return undef;
    }
    $settings_win = $app->open_window(
        title   => 'Settings',
        width   => 320,
        height  => 200,
        content => settings_html(),
    );
    # Restore last position
    my $sx = $store->get('settings.x', 100);
    my $sy = $store->get('settings.y', 100);
    $settings_win->set_position($sx, $sy);

    $settings_win->on_resize(sub {
        my ($w, $h) = @_;
        $store->set('settings.width',  $w);
        $store->set('settings.height', $h);
    });

    $settings_win->on_close(sub {
        # save position before close
        my ($x, $y) = $settings_win->get_position;
        $store->set('settings.x', $x);
        $store->set('settings.y', $y);
        return 1;
    });

    return undef;
});

$app->bind('set_theme', sub {
    my ($theme) = @_;
    $store->set('theme', $theme);
    # Refresh main window with new theme
    refresh_main();
    # Reload settings window to reflect the change
    if ($settings_win && !$settings_win->is_closed) {
        $settings_win->set_content(settings_html());
    }
    return undef;
});

$app->bind('clear_done', sub {
    @todos = grep { !$_->{done} } @todos;
    $store->set('todos', \@todos);
    refresh_main();
    return undef;
});

# -----------------------------------------------------------------------
# Restore persisted todos
# -----------------------------------------------------------------------

if (my $saved = $store->get('todos')) {
    @todos = @$saved;
    $next_id = (max(map { $_->{id} } @todos) // 0) + 1;
}

# -----------------------------------------------------------------------
# Main window close — close all children
# -----------------------------------------------------------------------

# Close all child windows when the app exits
END { $app->close }

# -----------------------------------------------------------------------
# Run
# -----------------------------------------------------------------------

$app->set_content(render_todos());
printf "Store path : %s\n", $store->path;
printf "Open windows: %d\n", $app->window_count;
$app->run;
