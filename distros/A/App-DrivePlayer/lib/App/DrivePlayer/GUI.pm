package App::DrivePlayer::GUI;

# GTK3-based music player GUI.

use App::DrivePlayer::Setup;
use Glib            qw( TRUE FALSE );
use Gtk3            '-init';
use POSIX           qw( WNOHANG );

use Google::RestApi;
use Google::RestApi::DriveApi3;
use App::DrivePlayer::Config;
use App::DrivePlayer::DB;
use App::DrivePlayer::Player;
use App::DrivePlayer::Scanner;
use App::DrivePlayer::SheetDB;

Readonly my $POLL_INTERVAL_MS => 500;

my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };

has config => (
    is      => 'lazy',
    isa     => InstanceOf['App::DrivePlayer::Config'],
    builder => sub { App::DrivePlayer::Config->new() },
);

has db => (
    is      => 'lazy',
    isa     => InstanceOf['App::DrivePlayer::DB'],
    builder => '_build_db',
);

has rest_api => ( is => 'rw', default => sub { undef } );
has drive    => ( is => 'rw', default => sub { undef } );
has player   => ( is => 'rw', default => sub { undef } );
has scanner  => ( is => 'rw', default => sub { undef } );

has _playlist        => ( is => 'rw', isa => ArrayRef, default => sub { [] } );
has _track_by_id     => ( is => 'rw', default => sub { {} } );
has _playing_row_ref => ( is => 'rw', default => sub { undef } );
has _playing_track_id => ( is => 'rw', default => sub { undef } );
has _progress_dragging => ( is => 'rw', isa => Bool, default => 0 );

# Widget accessors — set during _build_ui
has win                => ( is => 'rw' );
has sidebar_store      => ( is => 'rw' );
has sidebar_view       => ( is => 'rw' );
has alpha_view         => ( is => 'rw' );
has _alpha_category    => ( is => 'rw', default => sub { 'Artists' } );
has track_store        => ( is => 'rw' );
has _track_iter_map    => ( is => 'rw', default => sub { {} } );
has track_view         => ( is => 'rw' );
has track_count_label  => ( is => 'rw' );
has now_playing_label  => ( is => 'rw' );
has progress           => ( is => 'rw' );
has time_label         => ( is => 'rw' );
has dur_label          => ( is => 'rw' );
has play_btn           => ( is => 'rw' );
has prev_btn           => ( is => 'rw' );
has stop_btn           => ( is => 'rw' );
has next_btn           => ( is => 'rw' );
has vol_scale          => ( is => 'rw' );
has search_entry       => ( is => 'rw' );
has statusbar          => ( is => 'rw' );
has _status_ctx        => ( is => 'rw' );
with qw(
    App::DrivePlayer::GUI::MetadataFetch
    App::DrivePlayer::GUI::SheetSync
    App::DrivePlayer::GUI::FolderBrowse
);

sub _bearer_token {
    my ($self) = @_;
    return unless $self->rest_api;
    my %h = @{ $self->rest_api->auth->headers() };
    return $h{Authorization};
}

sub _build_db {
    my ($self) = @_;
    return App::DrivePlayer::DB->new(path => $self->config->db_path());
}

sub BUILD {
    my ($self) = @_;
    $self->_init_logging();
}

sub run {
    my ($self) = @_;
    my $db_is_new = !-f $self->config->db_path();
    $self->_build_ui();
    $self->_auto_sync_from_sheet_on_new_db() if $db_is_new;
    $self->_prune_removed_folders();
    $self->_load_library();

    Glib::Timeout->add($POLL_INTERVAL_MS, sub {
        $self->_player_poll();
        return TRUE;
    });

    Gtk3->main();
    $self->player->quit() if $self->player;
}

# ---- Initialisation ----

sub _init_logging {
    my ($self) = @_;
    $self->config->ensure_dirs();
    my $level = $self->config->log_level();
    my $file  = $self->config->log_file() // '/tmp/drive_player.log';

    my $log4perl_conf = "
        log4perl.rootLogger=$level, Screen, File
        log4perl.appender.Screen=Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern=%d [%p] %m%n
        log4perl.appender.File=Log::Log4perl::Appender::File
        log4perl.appender.File.filename=$file
        log4perl.appender.File.utf8=1
        log4perl.appender.File.layout=Log::Log4perl::Layout::PatternLayout
        log4perl.appender.File.layout.ConversionPattern=%d [%p] %m%n
    ";
    if (eval { require Log::Log4perl; 1 }) {
        Log::Log4perl->init(\$log4perl_conf);
        binmode STDERR, ':encoding(UTF-8)';
    }
}

sub _init_api {
    my ($self) = @_;
    return $self->rest_api if $self->rest_api;

    my $auth_cfg = $self->config->auth_config();
    unless ($auth_cfg->{client_id} && $auth_cfg->{client_secret}) {
        $self->_show_error(
            "Google API credentials not configured.\n\n" .
            "Open File > Settings and enter your OAuth Client ID and Secret.\n\n" .
            "You can obtain these from the Google Cloud Console under\n" .
            "APIs & Services > Credentials (OAuth 2.0 Client ID, Desktop app type)."
        );
        return;
    }
    unless (-f ($auth_cfg->{token_file} // '')) {
        $self->_show_error("OAuth token file not found: $auth_cfg->{token_file}\n\n" .
            "Run the token creator from p5-google-restapi:\n" .
            "  bin/google_restapi_oauth_token_creator");
        return;
    }

    my $api = eval { Google::RestApi->new(auth => $auth_cfg) };
    if ($@) {
        $self->_show_error("Failed to initialise Google API: $@");
        return;
    }
    $self->rest_api($api);
    $self->drive(Google::RestApi::DriveApi3->new(api => $api));

    $self->player(App::DrivePlayer::Player->new(
        auth            => $api->auth(),
        on_track_end    => sub { $self->_on_track_end() },
        on_position     => sub { $self->_on_position(@_) },
        on_state_change => sub { $self->_on_state_change(@_) },
    ));

    return $self->rest_api;
}

# ---- UI Construction ----

sub _build_ui {
    my ($self) = @_;

    Gtk3::Window::set_default_icon_name('multimedia-player');

    $self->win(Gtk3::Window->new('toplevel'));
    $self->win->set_title('Drive Player');
    $self->win->set_default_size(900, 600);
    $self->win->signal_connect(destroy => sub { $self->_quit() });

    my $vbox = Gtk3::Box->new('vertical', 0);
    $self->win->add($vbox);

    # Menu bar
    $vbox->pack_start($self->_build_menubar(), FALSE, FALSE, 0);

    # Toolbar
    $vbox->pack_start($self->_build_toolbar(), FALSE, FALSE, 0);

    # Main paned: sidebar | tracklist
    my $paned = Gtk3::Paned->new('horizontal');
    $paned->set_position(220);
    $vbox->pack_start($paned, TRUE, TRUE, 0);

    $paned->pack1($self->_build_sidebar(),   TRUE, TRUE);
    $paned->pack2($self->_build_tracklist(), TRUE, TRUE);

    # Search bar
    $vbox->pack_start($self->_build_searchbar(), FALSE, FALSE, 0);

    # Player controls
    $vbox->pack_start($self->_build_controls(), FALSE, FALSE, 0);

    # Status bar
    $self->statusbar(Gtk3::Statusbar->new());
    $self->_status_ctx($self->statusbar->get_context_id('main'));
    $vbox->pack_start($self->statusbar, FALSE, FALSE, 0);

    $self->win->show_all();
    $self->stop_btn->hide();   # hidden until playback starts
}

sub _build_menubar {
    my ($self) = @_;
    my $mb = Gtk3::MenuBar->new();

    # File menu
    my $file_menu = Gtk3::Menu->new();
    $self->_add_menu_item($file_menu, 'Add Music Folder…',  sub { $self->_add_folder_dialog() });
    $self->_add_menu_item($file_menu, 'Manage Folders…',    sub { $self->_manage_folders_dialog() });
    $file_menu->append(Gtk3::SeparatorMenuItem->new());
    $self->_add_menu_item($file_menu, 'Settings…',          sub { $self->_settings_dialog() });
    $file_menu->append(Gtk3::SeparatorMenuItem->new());
    $self->_add_menu_item($file_menu, 'Quit',               sub { $self->_quit() });
    my $file_item = Gtk3::MenuItem->new_with_label('File');
    $file_item->set_submenu($file_menu);
    $mb->append($file_item);

    # Library menu
    my $lib_menu = Gtk3::Menu->new();
    $self->_add_menu_item($lib_menu, 'Sync',                   sub { $self->_sync_all() });
    $self->_add_menu_item($lib_menu, 'Refresh',               sub { $self->_load_library() });
    $lib_menu->append(Gtk3::SeparatorMenuItem->new());
    my $fetch_item = $self->_add_menu_item($lib_menu, 'Fetch All Metadata', sub { $self->_toggle_metadata_fetch() });
    $self->_meta_fetch_item($fetch_item);
    $self->_add_menu_item($lib_menu, 'Retry Incomplete Metadata', sub { $self->_retry_incomplete_metadata() });
    $self->_add_menu_item($lib_menu, 'Reset Metadata Fetch',      sub { $self->_reset_metadata_fetch() });
    $lib_menu->append(Gtk3::SeparatorMenuItem->new());
    $self->_add_menu_item($lib_menu, 'Clear Library',           sub { $self->_clear_library() });
    my $lib_item = Gtk3::MenuItem->new_with_label('Library');
    $lib_item->set_submenu($lib_menu);
    $mb->append($lib_item);

    # Playback menu
    my $pb_menu = Gtk3::Menu->new();
    $self->_add_menu_item($pb_menu, 'Play / Pause',  sub { $self->_toggle_play() });
    $self->_add_menu_item($pb_menu, 'Stop',          sub { $self->_stop() });
    $self->_add_menu_item($pb_menu, 'Next Track',    sub { $self->_next_track() });
    $self->_add_menu_item($pb_menu, 'Previous Track',sub { $self->_prev_track() });
    my $pb_item = Gtk3::MenuItem->new_with_label('Playback');
    $pb_item->set_submenu($pb_menu);
    $mb->append($pb_item);

    return $mb;
}

sub _add_menu_item {
    my ($self, $menu, $label, $cb) = @_;
    my $item = Gtk3::MenuItem->new_with_label($label);
    $item->signal_connect(activate => $cb);
    $menu->append($item);
    return $item;
}

sub _build_toolbar {
    my ($self) = @_;
    my $tb = Gtk3::Toolbar->new();
    $tb->set_style('both-horiz');

    my $scan_btn = Gtk3::ToolButton->new(
        Gtk3::Image->new_from_icon_name('view-refresh', 'small-toolbar'),
        'Sync'
    );
    $scan_btn->signal_connect(clicked => sub { $self->_sync_all() });
    $tb->insert($scan_btn, -1);

    my $add_btn = Gtk3::ToolButton->new(
        Gtk3::Image->new_from_icon_name('folder-new', 'small-toolbar'),
        'Add Folder'
    );
    $add_btn->signal_connect(clicked => sub { $self->_add_folder_dialog() });
    $tb->insert($add_btn, -1);

    $tb->insert(Gtk3::SeparatorToolItem->new(), -1);

    my $settings_btn = Gtk3::ToolButton->new(
        Gtk3::Image->new_from_icon_name('preferences-system', 'small-toolbar'),
        'Settings'
    );
    $settings_btn->signal_connect(clicked => sub { $self->_settings_dialog() });
    $tb->insert($settings_btn, -1);

    return $tb;
}

sub _build_sidebar {
    my ($self) = @_;
    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic');
    $sw->set_size_request(100, 1);
    $sw->set_propagate_natural_height(FALSE);

    # TreeStore: label (str), type (str: 'category'|'artist'|'album'|'folder'),
    #            value (str: artist name, album name, folder_id)
    my $store = Gtk3::TreeStore->new('Glib::String', 'Glib::String', 'Glib::String');
    $self->sidebar_store($store);

    my $view = Gtk3::TreeView->new($store);
    $view->set_headers_visible(FALSE);
    $view->get_selection()->set_mode('single');
    $view->signal_connect('cursor-changed'   => sub { $self->_sidebar_activated($view) });
    $view->signal_connect('button-press-event' => sub { $self->_sidebar_button_press($view, $_[1]) });
    $self->sidebar_view($view);

    $view->set_size_request(100, 1);

    my $renderer = Gtk3::CellRendererText->new();
    $renderer->set(ellipsize => 'end');
    my $col = Gtk3::TreeViewColumn->new_with_attributes('', $renderer, text => 0);
    $col->set_sizing('fixed');
    $col->set_expand(TRUE);
    $view->append_column($col);
    $view->set_fixed_height_mode(TRUE);

    $sw->add($view);

    my $hbox = Gtk3::Box->new('horizontal', 0);
    $hbox->pack_start($self->_build_alpha_strip(), FALSE, FALSE, 0);
    $hbox->pack_start($sw, TRUE, TRUE, 0);
    return $hbox;
}

sub _build_alpha_strip {
    my ($self) = @_;

    my $css = Gtk3::CssProvider->new();
    $css->load_from_data(
        'treeview.alpha-nav { font-size: 10px; padding: 0; }'
        . ' treeview.alpha-nav row { min-height: 0; padding: 1px 0; }'
    );

    my $store = Gtk3::ListStore->new('Glib::String');
    for my $letter ('#', 'A' .. 'Z') {
        my $iter = $store->append();
        $store->set($iter, 0, $letter);
    }

    my $view = Gtk3::TreeView->new($store);
    $view->set_headers_visible(FALSE);
    $view->set_fixed_height_mode(TRUE);
    $view->set_can_focus(FALSE);
    $view->set_activate_on_single_click(TRUE);
    $view->get_style_context()->add_class('alpha-nav');
    $view->get_style_context()->add_provider($css, 600);
    $self->alpha_view($view);

    my $renderer = Gtk3::CellRendererText->new();
    $renderer->set(xalign => 0.5);
    my $col = Gtk3::TreeViewColumn->new_with_attributes('', $renderer, text => 0);
    $col->set_sizing('fixed');
    $col->set_fixed_width(32);
    $view->append_column($col);

    $view->signal_connect('row-activated' => sub {
        my ($tv, $path, $col) = @_;
        my $iter = $store->get_iter($path) or return;
        my $letter = $store->get($iter, 0);
        $self->_sidebar_jump_to_letter($letter);
        $tv->get_selection()->unselect_all();
    });

    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('never', 'automatic');
    $sw->set_size_request(32, 1);
    $sw->set_propagate_natural_height(FALSE);
    $sw->add($view);
    return $sw;
}

sub _sidebar_jump_to_letter {
    my ($self, $letter) = @_;
    my $cat_label = $self->_alpha_category or return;
    my $store = $self->sidebar_store;
    my $view  = $self->sidebar_view;

    my $cat_iter = $store->get_iter_first() or return;
    my $target;
    while (1) {
        if (($store->get($cat_iter, 0) // '') eq $cat_label) {
            $target = $store->get_path($cat_iter);  # snapshot path before iter moves
            last;
        }
        last unless $store->iter_next($cat_iter);
    }
    return unless $target;

    my $target_iter = $store->get_iter($target) or return;
    my $n = $store->iter_n_children($target_iter);
    for my $i (0 .. $n - 1) {
        my $child = $store->iter_nth_child($target_iter, $i) or next;
        my $label = $store->get($child, 0) // '';
        my $first = uc(substr($label, 0, 1));
        my $matches = $letter eq '#' ? ($first lt 'A' || $first gt 'Z')
                                     : $first eq $letter;
        next unless $matches;
        my $path = $store->get_path($child);
        $view->expand_to_path($path);
        $view->set_cursor($path, undef, FALSE);
        $view->scroll_to_cell($path, undef, TRUE, 0.0, 0.0);
        return;
    }
}

sub _update_alpha_category {
    my ($self, $label) = @_;
    my $enabled = defined $label
               && $label =~ / \A (?: Artists | Albums | Genres ) \z /x;
    $self->_alpha_category($enabled ? $label : undef);
    $self->alpha_view->set_sensitive($enabled ? TRUE : FALSE)
        if $self->alpha_view;
}

sub _build_tracklist {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 0);

    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic');
    $sw->set_size_request(-1, 1);
    $sw->set_propagate_natural_height(FALSE);
    $sw->set_kinetic_scrolling(FALSE);
    $sw->set_capture_button_press(FALSE);
    $sw->set_overlay_scrolling(FALSE);
    $vbox->pack_start($sw, TRUE, TRUE, 0);

    my $count_lbl = Gtk3::Label->new('');
    $count_lbl->set_xalign(1.0);
    $count_lbl->set_margin_end(6);
    $count_lbl->set_margin_top(2);
    $count_lbl->set_margin_bottom(2);
    $self->track_count_label($count_lbl);
    $vbox->pack_start($count_lbl, FALSE, FALSE, 0);

    # ListStore columns: id, track#, title, artist, album, genre, year, duration_str, drive_id
    my $store = Gtk3::ListStore->new(
        'Glib::Int',    # 0 db id
        'Glib::String', # 1 track#
        'Glib::String', # 2 title
        'Glib::String', # 3 artist
        'Glib::String', # 4 album
        'Glib::String', # 5 genre
        'Glib::String', # 6 year
        'Glib::String', # 7 duration
        'Glib::String', # 8 drive_id
    );
    $self->track_store($store);

    my $view = Gtk3::TreeView->new($store);
    $view->set_headers_visible(TRUE);
    $view->set_fixed_height_mode(TRUE);
    $view->get_selection()->set_mode('multiple');
    $view->signal_connect('row-activated' => sub { $self->_track_activated(@_) });
    $self->track_view($view);

    my @cols = (
        ['#',        1,  40],
        ['Title',    2, 220],
        ['Artist',   3, 160],
        ['Album',    4, 160],
        ['Genre',    5, 100],
        ['Year',     6,  60],
        ['Duration', 7,  65],
    );
    for my $col_def (@cols) {
        my ($title, $idx, $width) = @$col_def;
        my $r = Gtk3::CellRendererText->new();
        my $c = Gtk3::TreeViewColumn->new_with_attributes($title, $r, text => $idx);
        $c->set_resizable(TRUE);
        $c->set_sort_column_id($idx);
        $c->set_sizing('fixed');
        $c->set_fixed_width($width);
        $view->append_column($c);
    }

    # Take full control of left-click so GTK's default handler (which
    # calls set_cursor and auto-scrolls the clicked row into view) doesn't
    # shift the viewport between the clicks of a double-click.
    $view->signal_connect('button-press-event' => sub {
        my ($w, $event) = @_;

        if ($event->button == 3) {
            $self->_tracklist_context_menu($event);
            return TRUE;
        }

        return FALSE unless $event->button == 1;

        my ($path, $col) = $w->get_path_at_pos($event->x, $event->y);
        return FALSE unless $path;

        if ($event->type eq '2button-press') {
            $self->_play_at_path($path, no_scroll => 1);
            return TRUE;
        }

        my $sel   = $w->get_selection();
        my $state = $event->state;
        if ($state & 'control-mask') {
            $sel->path_is_selected($path)
                ? $sel->unselect_path($path)
                : $sel->select_path($path);
        }
        elsif ($state & 'shift-mask') {
            # Let GTK handle shift-click range extension.
            return FALSE;
        }
        else {
            $sel->unselect_all();
            $sel->select_path($path);
        }
        return TRUE;
    });

    $sw->add($view);
    return $vbox;
}

sub _build_searchbar {
    my ($self) = @_;
    my $hbox = Gtk3::Box->new('horizontal', 4);
    $hbox->set_border_width(2);

    my $label = Gtk3::Label->new('Search:');
    $hbox->pack_start($label, FALSE, FALSE, 4);

    my $entry = Gtk3::SearchEntry->new();
    $entry->set_placeholder_text('Artist, album or title…');
    $entry->signal_connect('search-changed' => sub { $self->_on_search($entry->get_text()) });
    $self->search_entry($entry);
    $hbox->pack_start($entry, TRUE, TRUE, 0);

    my $clear = Gtk3::Button->new_with_label('Clear');
    $clear->signal_connect(clicked => sub {
        $entry->set_text('');
        $self->_load_library();
    });
    $hbox->pack_start($clear, FALSE, FALSE, 0);

    return $hbox;
}

sub _build_controls {
    my ($self) = @_;
    my $frame = Gtk3::Frame->new();
    my $vbox  = Gtk3::Box->new('vertical', 2);
    $vbox->set_border_width(4);
    $frame->add($vbox);

    # Now-playing label
    $self->now_playing_label(Gtk3::Label->new('Not playing'));
    $self->now_playing_label->set_ellipsize('end');
    $self->now_playing_label->set_xalign(0.0);
    $vbox->pack_start($self->now_playing_label, FALSE, FALSE, 0);

    # Progress bar + time labels
    my $prog_hbox = Gtk3::Box->new('horizontal', 4);
    $self->time_label(Gtk3::Label->new('0:00'));
    $self->time_label->set_size_request(40, -1);
    $prog_hbox->pack_start($self->time_label, FALSE, FALSE, 0);

    $self->progress(Gtk3::Scale->new_with_range('horizontal', 0, 100, 1));
    $self->progress->set_draw_value(FALSE);
    $self->progress->set_range(0, 1);
    $self->progress->signal_connect('button-press-event' => sub {
        $self->_progress_dragging(1); return FALSE;
    });
    $self->progress->signal_connect('button-release-event' => sub {
        $self->_progress_dragging(0);
        $self->player->seek($self->progress->get_value()) if $self->player;
        return FALSE;
    });
    $prog_hbox->pack_start($self->progress, TRUE, TRUE, 0);

    $self->dur_label(Gtk3::Label->new('0:00'));
    $self->dur_label->set_size_request(40, -1);
    $prog_hbox->pack_start($self->dur_label, FALSE, FALSE, 0);
    $vbox->pack_start($prog_hbox, FALSE, FALSE, 0);

    # Buttons + volume
    my $btn_hbox = Gtk3::Box->new('horizontal', 4);
    $vbox->pack_start($btn_hbox, FALSE, FALSE, 0);

    $self->prev_btn($self->_icon_button('media-skip-backward', sub { $self->_prev_track() }));
    $self->play_btn($self->_icon_button('media-playback-start', sub { $self->_toggle_play() }));
    $self->stop_btn($self->_icon_button('media-playback-stop',  sub { $self->_stop() }));
    $self->next_btn($self->_icon_button('media-skip-forward',   sub { $self->_next_track() }));

    $btn_hbox->pack_start($self->prev_btn, FALSE, FALSE, 0);
    $btn_hbox->pack_start($self->play_btn, FALSE, FALSE, 0);
    $btn_hbox->pack_start($self->stop_btn, FALSE, FALSE, 0);
    $btn_hbox->pack_start($self->next_btn, FALSE, FALSE, 0);

    $btn_hbox->pack_start(Gtk3::Label->new(' Vol:'), FALSE, FALSE, 8);
    $self->vol_scale(Gtk3::Scale->new_with_range('horizontal', 0, 100, 1));
    $self->vol_scale->set_value(80);
    $self->vol_scale->set_size_request(100, -1);
    $self->vol_scale->set_draw_value(FALSE);
    $self->vol_scale->signal_connect('value-changed' => sub {
        $self->player->set_volume($self->vol_scale->get_value()) if $self->player;
    });
    $btn_hbox->pack_start($self->vol_scale, FALSE, FALSE, 0);

    return $frame;
}

sub _icon_button {
    my ($self, $icon_name, $cb) = @_;
    my $btn = Gtk3::Button->new();
    $btn->set_image(Gtk3::Image->new_from_icon_name($icon_name, 'button'));
    $btn->signal_connect(clicked => $cb);
    return $btn;
}

# ---- Library loading ----

sub _load_library {
    my ($self) = @_;
    $self->_populate_sidebar();
    $self->_populate_tracklist($self->db->all_tracks());
    my $count = $self->db->track_count();
    $self->_set_status("$count tracks in library");
}

sub _populate_sidebar {
    my ($self) = @_;
    my $store = $self->sidebar_store;
    $store->clear();

    # All Tracks
    my $all_iter = $store->append(undef);
    $store->set($all_iter, 0, 'All Tracks', 1, 'all', 2, '');

    # Artists
    my $art_iter = $store->append(undef);
    $store->set($art_iter, 0, 'Artists', 1, 'category', 2, '');
    for my $artist ($self->db->all_artists()) {
        my $iter = $store->append($art_iter);
        $store->set($iter, 0, $artist, 1, 'artist', 2, $artist);
    }

    # Albums
    my $alb_iter = $store->append(undef);
    $store->set($alb_iter, 0, 'Albums', 1, 'category', 2, '');
    for my $album ($self->db->all_albums()) {
        my $iter = $store->append($alb_iter);
        $store->set($iter, 0, $album, 1, 'album', 2, $album);
    }

    # Genres
    my $gen_iter = $store->append(undef);
    $store->set($gen_iter, 0, 'Genres', 1, 'category', 2, '');
    for my $genre ($self->db->all_genres()) {
        my $iter = $store->append($gen_iter);
        $store->set($iter, 0, $genre, 1, 'genre', 2, $genre);
    }

    # Folders
    my $fld_iter = $store->append(undef);
    $store->set($fld_iter, 0, 'Folders', 1, 'category', 2, '');
    for my $sf ($self->db->all_scan_folders()) {
        my $iter = $store->append($fld_iter);
        $store->set($iter, 0, $sf->{name}, 1, 'folder', 2, $sf->{drive_id});
    }

    $self->sidebar_view->expand_all();
}

sub _populate_tracklist {
    my ($self, @tracks) = @_;
    my $store = $self->track_store;
    $store->clear();
    $self->_track_iter_map({});
    $self->_track_by_id({});
    $self->_playlist(\@tracks);
    $self->_playing_row_ref(undef);
    $self->_playing_track_id(undef);

    for my $t (@tracks) {
        my $iter = $store->append();
        $store->set($iter,
            0, $t->{id}           // 0,
            1, _track_num_str($t->{track_number}),
            2, $t->{title}        // '(Unknown)',
            3, $t->{artist}       // '',
            4, $t->{album}        // '',
            5, $t->{genre}        // '',
            6, $t->{year}         // '',
            7, _dur_str($t->{duration_ms}),
            8, $t->{drive_id}     // '',
        );
        if ($t->{id}) {
            $self->_track_iter_map->{$t->{id}} = $iter;
            $self->_track_by_id->{$t->{id}}    = $t;
        }
    }

    my $n = scalar @tracks;
    $self->track_count_label->set_text($n == 1 ? '1 track' : "$n tracks");
}

sub _refresh_track_row {
    my ($self, $track_id) = @_;
    my $iter = $self->_track_iter_map->{$track_id} or return;
    my $t    = $self->db->get_track($track_id)      or return;
    $self->track_store->set($iter,
        1, _track_num_str($t->{track_number}),
        3, $t->{artist}   // '',
        4, $t->{album}    // '',
        5, $t->{genre}    // '',
        6, $t->{year}     // '',
        7, _dur_str($t->{duration_ms}),
    );
}

# ---- Playback ----

sub _track_activated {
    my ($self, $view, $path, $col) = @_;
    $self->_play_at_path($path, no_scroll => 1);
}

sub _track_at_path {
    my ($self, $path) = @_;
    my $iter = $self->track_store->get_iter($path) or return;
    my $id   = $self->track_store->get($iter, 0);
    return $self->_track_by_id->{$id};
}

sub _current_path {
    my ($self) = @_;
    my $ref = $self->_playing_row_ref or return;
    return unless $ref->valid();
    return $ref->get_path();
}

sub _play_at_path {
    my ($self, $path, %opts) = @_;
    my $track = $self->_track_at_path($path) or return;
    return unless $self->_init_api();

    eval { $self->player->play($track) };
    if ($@) {
        $self->_show_error("Playback error: $@");
        return;
    }

    $self->_playing_track_id($track->{id});
    $self->_playing_row_ref(Gtk3::TreeRowReference->new($self->track_store, $path));
    $self->_update_now_playing($track);
    $self->_highlight_path($path) unless $opts{no_scroll};
}

sub _toggle_play {
    my ($self) = @_;
    if (!$self->player || $self->player->state eq 'stop') {
        my $sel = $self->track_view->get_selection();
        my (undef, @paths) = $sel->get_selected_rows();
        my $path = @paths ? $paths[0] : Gtk3::TreePath->new_from_indices(0);
        $self->_play_at_path($path);
    } else {
        return unless $self->_init_api();
        $self->player->pause_resume();
    }
}

sub _stop {
    my ($self) = @_;
    return unless $self->player;
    $self->player->stop();
    $self->progress->set_value(0);
    $self->time_label->set_text('0:00');
    $self->now_playing_label->set_text('Not playing');
}

sub _next_track {
    my ($self) = @_;
    my $path = $self->_current_path();
    if ($path) {
        my $iter = $self->track_store->get_iter($path);
        return unless $iter && $self->track_store->iter_next($iter);
        $self->_play_at_path($self->track_store->get_path($iter));
    } else {
        $self->_play_at_path(Gtk3::TreePath->new_from_indices(0))
            if @{ $self->_playlist };
    }
}

sub _prev_track {
    my ($self) = @_;
    my $path = $self->_current_path() or return;
    return unless $path->prev();
    $self->_play_at_path($path);
}

# ---- Player callbacks ----

sub _on_track_end {
    my ($self) = @_;
    $self->_next_track();
}

sub _on_position {
    my ($self, $pos, $dur) = @_;
    return if $self->_progress_dragging;
    $self->progress->set_range(0, $dur) if $dur;
    $self->progress->set_value($pos)    if defined $pos;
    $self->time_label->set_text(_sec_str($pos));
    $self->dur_label->set_text(_sec_str($dur));

    # Persist duration when mpv reports it for a track that doesn't have one yet.
    if ($dur && $dur > 0) {
        my $id    = $self->_playing_track_id;
        my $track = $id ? $self->_track_by_id->{$id} : undef;
        if ($track && !$track->{duration_ms}) {
            my $ms = int($dur * 1000);
            $track->{duration_ms} = $ms;   # mutate to prevent firing again
            $self->db->update_track_metadata($track->{id}, duration_ms => $ms);
            $self->_refresh_track_row($track->{id});
        }
    }
}

sub _on_state_change {
    my ($self, $state) = @_;
    my $icon = $state eq 'play' ? 'media-playback-pause' : 'media-playback-start';
    $self->play_btn->set_image(Gtk3::Image->new_from_icon_name($icon, 'button'));
    if ($state eq 'stop') {
        $self->stop_btn->hide();
    } else {
        $self->stop_btn->show();
    }
}

sub _player_poll {
    my ($self) = @_;
    if ($self->player) {
        eval { $self->player->poll() };
        $log->warn("Player poll error: $@") if $@ && $log;
    }
}

# ---- Sidebar activation ----

sub _sidebar_activated {
    my ($self, $view) = @_;
    my ($path) = $view->get_cursor();
    return unless $path;
    my $store = $self->sidebar_store;
    my $iter  = $store->get_iter($path);
    my $type  = $store->get($iter, 1);
    my $value = $store->get($iter, 2);
    my $label = $store->get($iter, 0);

    # Resolve the alpha-nav category for the current selection. Leaf rows look
    # up their parent category's label; category headers use their own label.
    my $cat_label;
    if ($type eq 'category') {
        $cat_label = $label;
    } elsif ($type =~ / \A (?: artist | album | genre ) \z /x) {
        my $parent = $store->iter_parent($iter);
        $cat_label = $parent ? $store->get($parent, 0) : undef;
    }
    $self->_update_alpha_category($cat_label);

    if ($type eq 'all') {
        $self->_populate_tracklist($self->db->all_tracks());
    } elsif ($type eq 'artist') {
        $self->_populate_tracklist($self->db->tracks_by_artist($value));
    } elsif ($type eq 'album') {
        $self->_populate_tracklist($self->db->tracks_by_album($value));
    } elsif ($type eq 'genre') {
        $self->_populate_tracklist($self->db->tracks_by_genre($value));
    } elsif ($type eq 'folder') {
        my $sf = $self->db->get_scan_folder_by_drive_id($value) or return;
        $self->_populate_tracklist($self->db->tracks_by_scan_folder($sf->{id}));
    } else {
        return;  # category header selected — no tracklist change
    }

    $self->_set_status(scalar(@{ $self->_playlist }) . ' tracks');
}

sub _sidebar_button_press {
    my ($self, $view, $event) = @_;
    return FALSE unless $event->button == 3;

    my ($path) = $view->get_path_at_pos($event->x, $event->y);
    return FALSE unless $path;

    my $store = $self->sidebar_store;
    my $iter  = $store->get_iter($path);
    my $type  = $store->get($iter, 1);
    return FALSE unless $type eq 'folder';

    my $drive_id = $store->get($iter, 2);
    my $sf       = $self->db->get_scan_folder_by_drive_id($drive_id) or return FALSE;

    my $menu = Gtk3::Menu->new();
    $self->_add_menu_item($menu, 'Fetch Metadata for This Folder', sub {
        $self->_stop_metadata_fetch() if $self->_meta_watch_id;
        $self->_fetch_all_metadata($sf->{id});
    });
    $menu->show_all();
    $menu->popup_at_pointer($event);
    return TRUE;
}

# ---- Search ----

sub _on_search {
    my ($self, $query) = @_;
    if (length $query >= 2) {
        $self->_populate_tracklist($self->db->search_tracks($query));
    } elsif (length $query == 0) {
        $self->_populate_tracklist($self->db->all_tracks());
    }
}

# ---- Scanning ----

sub _sync_all {
    my ($self) = @_;
    return unless $self->_init_api();

    my @folders = @{ $self->config->music_folders() };
    unless (@folders) {
        $self->_show_error("No music folders configured.\nUse File → Add Music Folder.");
        return;
    }

    $self->_show_sync_dialog(\@folders);
}

sub _show_sync_dialog {
    my ($self, $folders) = @_;

    my $dlg = Gtk3::Dialog->new_with_buttons(
        'Syncing Library', $self->win,
        [qw/ modal destroy-with-parent /],
        'Stop', 'cancel',
    );
    $dlg->set_default_size(400, 160);

    my $content = $dlg->get_content_area();
    my $vbox = Gtk3::Box->new('vertical', 8);
    $vbox->set_border_width(12);
    $content->pack_start($vbox, TRUE, TRUE, 0);

    my $status_lbl = Gtk3::Label->new('Preparing…');
    $status_lbl->set_xalign(0.0);
    $status_lbl->set_ellipsize('middle');
    $vbox->pack_start($status_lbl, FALSE, FALSE, 0);

    my $progress = Gtk3::ProgressBar->new();
    $progress->set_pulse_step(0.05);
    $vbox->pack_start($progress, FALSE, FALSE, 0);

    my $count_lbl = Gtk3::Label->new('0 tracks found');
    $count_lbl->set_xalign(0.0);
    $vbox->pack_start($count_lbl, FALSE, FALSE, 0);

    $dlg->show_all();

    my $track_count    = 0;
    my $total_removed  = 0;
    my $total          = scalar @$folders;
    my $current        = 0;
    my $stopped        = FALSE;

    my $scanner = App::DrivePlayer::Scanner->new(
        drive    => $self->drive,
        db       => $self->db,
        on_progress => sub {
            my ($msg) = @_;
            $status_lbl->set_text($msg);
            $progress->pulse();
            Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();
        },
        on_track_found => sub {
            $track_count++;
            $count_lbl->set_text("$track_count tracks found");
            Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();
        },
        on_large_deletion => sub {
            my ($count, $folder_name) = @_;
            my $confirm = Gtk3::MessageDialog->new(
                $self->win, 'destroy-with-parent', 'warning', 'yes-no',
                "$count tracks would be removed from \"$folder_name\".\n\nProceed with deletion?",
            );
            my $response = $confirm->run();
            $confirm->destroy();
            return $response eq 'yes';
        },
    );
    $self->scanner($scanner);

    $dlg->signal_connect(response => sub {
        $stopped = TRUE;
        $scanner->stop();
    });

    for my $folder (@$folders) {
        last if $stopped;
        $current++;
        $status_lbl->set_text("Syncing folder $current/$total: $folder->{name}");
        $progress->set_fraction($current / ($total + 1));
        Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();

        my $result = eval { $scanner->scan_folder($folder->{id}, $folder->{name}) };
        if ($@) {
            $self->_set_status("Error syncing $folder->{name}: $@");
        } else {
            $total_removed += $result->{removed_tracks};
        }
    }

    my $done_msg = "Done. $track_count tracks";
    $done_msg   .= ", $total_removed removed" if $total_removed > 0;
    $done_msg   .= '.';
    $progress->set_fraction(1.0);
    $status_lbl->set_text($done_msg);
    Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();
    sleep 1;

    $dlg->destroy();
    $self->_load_library();
    $self->_sync_with_sheet() unless $stopped;
}

# ---- Dialogs ----

sub _settings_dialog {
    my ($self) = @_;
    my $dlg = Gtk3::Dialog->new_with_buttons(
        'Settings', $self->win,
        [qw/ modal destroy-with-parent /],
        'Save',   'ok',
        'Cancel', 'cancel',
    );
    $dlg->set_default_size(520, -1);

    my $vbox = $dlg->get_content_area();
    $vbox->set_spacing(0);

    # ---- Google API credentials ----
    my $auth_frame = Gtk3::Frame->new('Google API Credentials');
    $auth_frame->set_border_width(8);
    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(8);
    $grid->set_column_spacing(8);
    $grid->set_border_width(8);
    $auth_frame->add($grid);
    $vbox->pack_start($auth_frame, FALSE, FALSE, 0);

    my $row = 0;
    my %entries;
    for my $field (
        ['client_id',     'OAuth Client ID:',
         'OAuth 2.0 Client ID from Google Cloud Console (Desktop app type).'],
        ['client_secret', 'OAuth Client Secret:',
         'OAuth 2.0 Client Secret paired with the Client ID above.'],
        ['token_file',    'Token File:',
         'Path to the OAuth2 token created by running '
         . 'google_restapi_oauth_token_creator.'],
    ) {
        my ($key, $lbl, $tip) = @$field;
        my $lbl_w = Gtk3::Label->new($lbl);
        $lbl_w->set_xalign(1.0);
        $lbl_w->set_tooltip_text($tip);
        $grid->attach($lbl_w, 0, $row, 1, 1);
        my $e = Gtk3::Entry->new();
        $e->set_hexpand(TRUE);
        $e->set_text($self->config->auth_config()->{$key} // '');
        $e->set_visibility(FALSE) if $key eq 'client_secret';
        $e->set_tooltip_text($tip);
        $grid->attach($e, 1, $row, 1, 1);
        $entries{$key} = $e;
        $row++;
    }

    my $auth_note = Gtk3::Label->new();
    $auth_note->set_markup(
        '<span size="small" foreground="#555555">'
        . 'Create a Desktop-app OAuth client at '
        . '<a href="https://console.cloud.google.com/apis/credentials">'
        . 'Google Cloud Console → Credentials</a>, then enable the '
        . '<a href="https://console.cloud.google.com/apis/library/drive.googleapis.com">'
        . 'Drive API</a>.  Generate the token file by running '
        . '<tt>google_restapi_oauth_token_creator</tt> in a terminal.'
        . '</span>'
    );
    $auth_note->set_xalign(0.0);
    $auth_note->set_line_wrap(TRUE);
    $auth_note->set_max_width_chars(60);
    $grid->attach($auth_note, 1, $row, 1, 1);

    # ---- Google Sheet sync ----
    my $sheet_frame = Gtk3::Frame->new('Google Sheet Sync');
    $sheet_frame->set_border_width(8);
    my $sheet_grid = Gtk3::Grid->new();
    $sheet_grid->set_row_spacing(8);
    $sheet_grid->set_column_spacing(8);
    $sheet_grid->set_border_width(8);
    $sheet_frame->add($sheet_grid);
    $vbox->pack_start($sheet_frame, FALSE, FALSE, 0);

    my $sid_lbl = Gtk3::Label->new('Spreadsheet ID:');
    $sid_lbl->set_xalign(1.0);
    $sheet_grid->attach($sid_lbl, 0, 0, 1, 1);

    my $sid_box = Gtk3::Box->new('horizontal', 6);
    my $sid_entry = Gtk3::Entry->new();
    $sid_entry->set_hexpand(TRUE);
    $sid_entry->set_text($self->config->sheet_id());
    $sid_entry->set_placeholder_text('Paste spreadsheet ID, or click Find or Create');
    $sid_entry->set_tooltip_text(
        'The spreadsheet ID is the long string between "/d/" and "/edit" '
        . 'in a Google Sheets URL.  Leave blank and click "Find or Create" '
        . 'to have DrivePlayer find or create a sheet for you.'
    );
    $sid_lbl->set_tooltip_text($sid_entry->get_tooltip_text());
    $sid_box->pack_start($sid_entry, TRUE, TRUE, 0);

    my $create_btn = Gtk3::Button->new_with_label('Find or Create…');
    $create_btn->set_tooltip_text('Use existing DrivePlayer Library spreadsheet, or create one');
    $create_btn->signal_connect(clicked => sub {
        return unless $self->_init_api();
        $create_btn->set_sensitive(FALSE);
        $create_btn->set_label('Searching…');
        Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();

        my $id;
        my @found = eval {
            $self->drive->list(
                filter => "name='DrivePlayer Library' and mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
                params => { fields => 'files(id,name)', pageSize => 1 },
            );
        };
        if ($@) {
            $self->_show_error("Drive search failed:\n$@");
        } elsif (@found) {
            $id = $found[0]{id};
        } else {
            $create_btn->set_label('Creating…');
            Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();
            my $sheet = App::DrivePlayer::SheetDB->new(api => $self->rest_api);
            $id = eval { $sheet->create() };
            $self->_show_error("Failed to create spreadsheet:\n$@") if $@;
        }
        $sid_entry->set_text($id) if $id;
        $create_btn->set_label('Find or Create…');
        $create_btn->set_sensitive(TRUE);
    });
    $sid_box->pack_start($create_btn, FALSE, FALSE, 0);
    $sheet_grid->attach($sid_box, 1, 0, 1, 1);

    my $sheet_note = Gtk3::Label->new();
    $sheet_note->set_markup(
        '<span size="small" foreground="#555555">'
        . 'The library syncs to this sheet automatically after each '
        . 'Library → Sync.  Useful for sharing metadata across devices or '
        . 'editing tags in '
        . '<a href="https://sheets.google.com/">Google Sheets</a>.'
        . '</span>'
    );
    $sheet_note->set_xalign(0.0);
    $sheet_note->set_line_wrap(TRUE);
    $sheet_note->set_max_width_chars(60);
    $sheet_grid->attach($sheet_note, 1, 1, 1, 1);

    # ---- Acoustic fingerprinting ----
    my $fp_frame = Gtk3::Frame->new('Acoustic Fingerprinting (AcoustID)');
    $fp_frame->set_border_width(8);
    my $fp_grid = Gtk3::Grid->new();
    $fp_grid->set_row_spacing(8);
    $fp_grid->set_column_spacing(8);
    $fp_grid->set_border_width(8);
    $fp_frame->add($fp_grid);
    $vbox->pack_start($fp_frame, FALSE, FALSE, 0);

    # fpcalc status row
    my $fp_lbl = Gtk3::Label->new('fpcalc:');
    $fp_lbl->set_xalign(1.0);
    $fp_grid->attach($fp_lbl, 0, 0, 1, 1);

    my $fp_status = Gtk3::Label->new();
    $fp_status->set_xalign(0.0);

    my $install_btn = Gtk3::Button->new_with_label('Install…');
    $install_btn->set_tooltip_text(
        'Installs libchromaprint-tools via apt (requires administrator password)'
    );

    my $fp_hbox = Gtk3::Box->new('horizontal', 8);
    $fp_hbox->pack_start($fp_status,    FALSE, FALSE, 0);
    $fp_hbox->pack_start($install_btn,  FALSE, FALSE, 0);
    $fp_grid->attach($fp_hbox, 1, 0, 1, 1);

    # Helper: refresh the fpcalc status label
    my $refresh_fp_status = sub {
        if (App::DrivePlayer::MetadataFetcher::fpcalc_available()) {
            $fp_status->set_markup('<span foreground="#2d862d"><b>Installed</b></span>');
            $install_btn->hide();
        }
        else {
            $fp_status->set_markup(
                '<span foreground="#cc0000">Not installed</span>'
                . '  <span size="small" foreground="#666666">'
                . '(needed for fingerprint-based lookup)</span>'
            );
            $install_btn->show();
        }
    };
    $refresh_fp_status->();

    $install_btn->signal_connect(clicked => sub {
        $install_btn->set_sensitive(FALSE);
        $fp_status->set_markup('<span foreground="#666666">Installing…</span>');
        Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();

        my $pid = fork();
        if (!defined $pid) {
            $fp_status->set_markup('<span foreground="#cc0000">Fork failed</span>');
            $install_btn->set_sensitive(TRUE);
            return;
        }
        if ($pid == 0) {
            exec('pkexec', 'apt-get', 'install', '-y', 'libchromaprint-tools')
                or POSIX::_exit(1);
        }

        # Poll every 500 ms until the child exits
        Glib::Timeout->add(500, sub {
            my $res = waitpid($pid, WNOHANG());
            if ($res == $pid) {
                $refresh_fp_status->();
                $install_btn->set_sensitive(TRUE);
                return FALSE;   # remove timer
            }
            return TRUE;        # keep polling
        });
    });

    # AcoustID API key
    my $aid_lbl = Gtk3::Label->new('AcoustID API Key:');
    $aid_lbl->set_xalign(1.0);
    $fp_grid->attach($aid_lbl, 0, 1, 1, 1);

    my $aid_entry = Gtk3::Entry->new();
    $aid_entry->set_hexpand(TRUE);
    $aid_entry->set_text($self->config->acoustid_key());
    $aid_entry->set_placeholder_text('Get a free key at acoustid.org');
    $aid_entry->set_tooltip_text(
        'Free AcoustID API key — used with fpcalc to look up missing tags '
        . 'by acoustic fingerprint.'
    );
    $aid_lbl->set_tooltip_text($aid_entry->get_tooltip_text());
    $fp_grid->attach($aid_entry, 1, 1, 1, 1);

    $fp_lbl->set_tooltip_text(
        'fpcalc (from chromaprint) generates audio fingerprints for '
        . 'acoustic-ID lookup.  Install it via apt if missing.'
    );

    my $aid_note = Gtk3::Label->new();
    $aid_note->set_markup(
        '<span size="small" foreground="#555555">'
        . 'Register a free application at '
        . '<a href="https://acoustid.org/new-application">acoustid.org</a> '
        . 'to obtain a key.  '
        . '<a href="https://acoustid.org/">More info</a>.'
        . '</span>'
    );
    $aid_note->set_xalign(0.0);
    $aid_note->set_line_wrap(TRUE);
    $aid_note->set_max_width_chars(60);
    $fp_grid->attach($aid_note, 1, 2, 1, 1);

    # ---- Config file path (informational) ----
    my $info_grid = Gtk3::Grid->new();
    $info_grid->set_row_spacing(4);
    $info_grid->set_column_spacing(8);
    $info_grid->set_border_width(8);
    $vbox->pack_start($info_grid, FALSE, FALSE, 0);

    my $cfg_key = Gtk3::Label->new('Config file:');
    $cfg_key->set_xalign(1.0);
    $info_grid->attach($cfg_key, 0, 0, 1, 1);
    my $cfg_lbl = Gtk3::Label->new($self->config->config_file());
    $cfg_lbl->set_xalign(0.0);
    $cfg_lbl->set_selectable(TRUE);
    $info_grid->attach($cfg_lbl, 1, 0, 1, 1);

    $dlg->show_all();
    # Re-apply visibility after show_all (show_all overrides hide())
    $refresh_fp_status->();

    my $response = $dlg->run();

    if ($response eq 'ok') {
        my $auth = $self->config->auth_config();
        for my $key (keys %entries) {
            $auth->{$key} = $entries{$key}->get_text();
        }
        $self->config->_data->{acoustid_key} = $aid_entry->get_text();
        $self->config->_data->{sheet_id}     = $sid_entry->get_text();
        $self->config->save();
        $self->_set_status('Settings saved. Restart to apply API credential changes.');
    }
    $dlg->destroy();
}

sub _tracklist_context_menu {
    my ($self, $event) = @_;

    my ($path) = $self->track_view->get_path_at_pos($event->x, $event->y);
    return unless $path;
    $self->track_view->get_selection()->select_path($path);
    my $track = $self->_track_at_path($path);

    my $menu = Gtk3::Menu->new();

    my $play_item = Gtk3::MenuItem->new_with_label('Play');
    $play_item->signal_connect(activate => sub { $self->_play_at_path($path) });
    $menu->append($play_item);

    my $edit_item = Gtk3::MenuItem->new_with_label('Edit Metadata…');
    $edit_item->signal_connect(activate => sub {
        $self->_edit_metadata_dialog($track) if $track;
    });
    $menu->append($edit_item);

    my $fetch_item = Gtk3::MenuItem->new_with_label('Fetch Metadata…');
    $fetch_item->signal_connect(activate => sub {
        $self->_fetch_track_metadata($track) if $track;
    });
    $menu->append($fetch_item);

    $menu->show_all();
    $menu->popup_at_pointer($event);
}

sub _edit_metadata_dialog {
    my ($self, $track) = @_;

    my $dlg = Gtk3::Dialog->new_with_buttons(
        'Edit Metadata', $self->win,
        [qw/ modal destroy-with-parent /],
        'Save',   'ok',
        'Cancel', 'cancel',
    );
    $dlg->set_default_size(460, 280);

    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(6);
    $grid->set_column_spacing(8);
    $grid->set_border_width(12);
    $dlg->get_content_area()->add($grid);

    my %entries;
    my $row = 0;
    for my $field (
        [ title        => 'Title:'        ],
        [ artist       => 'Artist:'       ],
        [ album        => 'Album:'        ],
        [ genre        => 'Genre:'        ],
        [ track_number => 'Track Number:' ],
        [ year         => 'Year:'         ],
        [ comment      => 'Comment:'      ],
    ) {
        my ($key, $lbl) = @$field;
        my $label = Gtk3::Label->new($lbl);
        $label->set_xalign(1.0);
        $grid->attach($label, 0, $row, 1, 1);
        my $entry = Gtk3::Entry->new();
        $entry->set_hexpand(TRUE);
        $entry->set_text($track->{$key} // '');
        $grid->attach($entry, 1, $row, 1, 1);
        $entries{$key} = $entry;
        $row++;
    }

    $dlg->show_all();
    if ($dlg->run() eq 'ok') {
        my %fields;
        for my $key (keys %entries) {
            my $val = $entries{$key}->get_text();
            $fields{$key} = length($val) ? $val : undef;
        }
        # Coerce numeric fields
        for my $key (qw( track_number year )) {
            $fields{$key} = $fields{$key} ? int($fields{$key}) : undef;
        }
        $self->db->update_track_metadata($track->{id}, %fields);
        $self->_load_library();
        $self->_auto_sync_to_sheet();
    }
    $dlg->destroy();
}

sub _clear_library {
    my ($self) = @_;
    my $dlg = Gtk3::MessageDialog->new(
        $self->win, 'destroy-with-parent', 'question', 'yes-no',
        'Clear the entire music library? This will remove all scanned tracks.'
    );
    my $response = $dlg->run();
    $dlg->destroy();
    return unless $response eq 'yes';

    for my $sf ($self->db->all_scan_folders()) {
        $self->db->delete_scan_folder($sf->{drive_id});
    }
    $self->_load_library();
    $self->_set_status('Library cleared.');
}

# ---- Helpers ----

sub _update_now_playing {
    my ($self, $track) = @_;
    my $text = '';
    $text .= $track->{artist} . ' — ' if $track->{artist};
    $text .= $track->{title} // '(Unknown)';
    $text .= '  [' . $track->{album} . ']' if $track->{album};
    $self->now_playing_label->set_text($text);
    $self->win->set_title("Drive Player — $text");
}

sub _highlight_path {
    my ($self, $path) = @_;
    my $view = $self->track_view;
    my $sel  = $view->get_selection();
    $sel->unselect_all();
    $sel->select_path($path);

    # Only scroll if the row isn't already visible — re-centring an on-screen
    # row is the "extra scrolling" the user sees.
    my ($first, $last) = $view->get_visible_range();
    return if $first && $last
           && $path->compare($first) >= 0
           && $path->compare($last)  <= 0;

    $view->scroll_to_cell($path, undef, TRUE, 0.5, 0.0);
}

sub _set_status {
    my ($self, $msg) = @_;
    $self->statusbar->pop($self->_status_ctx);
    $self->statusbar->push($self->_status_ctx, $msg);
}

sub _show_error {
    my ($self, $msg) = @_;
    my $dlg = Gtk3::MessageDialog->new(
        $self->win, 'destroy-with-parent', 'error', 'ok', $msg
    );
    $dlg->run();
    $dlg->destroy();
}

sub _quit {
    my ($self) = @_;
    $self->_stop_metadata_fetch() if $self->_meta_watch_id;
    $self->player->quit() if $self->player;
    Gtk3->main_quit();
}

# ---- Formatting helpers ----

sub _dur_str {
    my ($ms) = @_;
    return '' unless defined $ms && $ms > 0;
    return _sec_str($ms / 1000);
}

sub _sec_str {
    my ($sec) = @_;
    return '0:00' unless defined $sec;
    $sec = int($sec);
    my $m = int($sec / 60);
    my $s = $sec % 60;
    return sprintf("%d:%02d", $m, $s);
}

sub _track_num_str {
    my ($n) = @_;
    return '' unless defined $n && $n > 0;
    return sprintf("%02d", $n);
}

1;

__END__

=head1 NAME

App::DrivePlayer::GUI - GTK3 application window for DrivePlayer

=head1 SYNOPSIS

  use App::DrivePlayer::GUI;

  App::DrivePlayer::GUI->new->run;

=head1 DESCRIPTION

The top-level L<Moo> class that constructs and drives the GTK3 user
interface.  Responsibilities include:

=over 4

=item *

Building the main window with a sidebar (artists / albums / folders), a
track list, and playback controls (play/pause, stop, seek, volume).

=item *

Lazily initialising the Google REST API connection and
L<App::DrivePlayer::Player> on first use, so start-up is fast even when network
access is unavailable.

=item *

Running folder scans (via L<App::DrivePlayer::Scanner>) in a background thread
with live progress reporting.

=item *

Persisting configuration changes (music folder list, OAuth2 credentials)
through L<App::DrivePlayer::Config>.

=back

Requires the GTK3 system libraries and the L<Gtk3> and L<Glib> Perl
modules.  Not covered by the unit test suite.

=head1 METHODS

=head2 new

  my $gui = App::DrivePlayer::GUI->new;

Constructs the application object.  The window is not shown until L</run>
is called.

=head2 run

  $gui->run;

Build and display the main window, then enter the GTK3 main loop.  Does not
return until the window is closed.

=cut
