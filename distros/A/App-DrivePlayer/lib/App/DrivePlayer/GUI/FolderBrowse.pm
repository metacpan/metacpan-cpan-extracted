package App::DrivePlayer::GUI::FolderBrowse;

# Moo role: Drive folder browsing and management dialogs.

use strict;
use warnings;
use utf8;
use Moo::Role;

use Glib  qw( TRUE FALSE );
use Gtk3  '-init';

sub _add_folder_dialog {
    my ($self) = @_;
    return unless $self->_init_api();

    my $dlg = Gtk3::Dialog->new_with_buttons(
        'Add Music Folder', $self->win,
        [qw/ modal destroy-with-parent /],
        'OK',     'ok',
        'Cancel', 'cancel',
    );
    $dlg->set_default_size(480, 150);

    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(6);
    $grid->set_column_spacing(8);
    $grid->set_border_width(12);
    $dlg->get_content_area()->add($grid);

    $grid->attach(Gtk3::Label->new('Drive Folder:'), 0, 0, 1, 1);
    my $id_box     = Gtk3::Box->new('horizontal', 4);
    my $id_entry   = Gtk3::Entry->new();
    $id_entry->set_placeholder_text('Folder ID or paste from Drive URL');
    $id_entry->set_hexpand(TRUE);
    my $browse_btn = Gtk3::Button->new_with_label('Browse…');
    $id_box->pack_start($id_entry,   TRUE,  TRUE,  0);
    $id_box->pack_start($browse_btn, FALSE, FALSE, 0);
    $grid->attach($id_box, 1, 0, 1, 1);

    $grid->attach(Gtk3::Label->new('Display Name:'), 0, 1, 1, 1);
    my $name_entry = Gtk3::Entry->new();
    $name_entry->set_placeholder_text('e.g. My Music');
    $name_entry->set_hexpand(TRUE);
    $grid->attach($name_entry, 1, 1, 1, 1);

    # When a Drive URL is pasted, extract the folder ID and look up its name.
    $id_entry->signal_connect(changed => sub {
        my $text = $id_entry->get_text();
        if (my ($extracted) = $text =~ m{drive\.google\.com/\S*?/([a-zA-Z0-9_-]{25,})}x) {
            $id_entry->set_text($extracted);   # triggers changed again with bare ID — no-op second time
            if ($name_entry->get_text() eq '') {
                my $name = $self->_fetch_drive_name($extracted);
                $name_entry->set_text($name) if $name;
            }
        }
    });

    $browse_btn->signal_connect(clicked => sub {
        if (my $folder = $self->_browse_folder_dialog($dlg)) {
            $id_entry->set_text($folder->{id});
            $name_entry->set_text($folder->{name}) if $name_entry->get_text() eq '';
        }
    });

    $dlg->show_all();
    my $response = $dlg->run();

    if ($response eq 'ok') {
        my $id   = $id_entry->get_text();
        my $name = $name_entry->get_text() || 'Music Folder';
        if ($id) {
            $self->config->add_music_folder($id, $name);
            $self->config->save();
            $self->_set_status("Added folder: $name. Use Library \x{2192} Sync to index it.");
        }
    }
    $dlg->destroy();
    return;
}

sub _fetch_drive_name {
    my ($self, $folder_id) = @_;
    my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };
    my $meta = eval { $self->drive->file(id => $folder_id)->get(fields => 'id,name') };
    $log->warn("Failed to fetch Drive name for $folder_id: $@") if $@ && $log;
    return $meta ? $meta->{name} : undef;
}

sub _browse_folder_dialog {
    my ($self, $parent) = @_;
    $parent //= $self->win;

    my $dlg = Gtk3::Dialog->new_with_buttons(
        'Browse Drive Folders', $parent,
        [qw/ modal destroy-with-parent /],
        'Select', 'ok',
        'Cancel', 'cancel',
    );
    $dlg->set_default_size(460, 420);
    $dlg->set_response_sensitive('ok', FALSE);

    # TreeStore columns: 0=name 1=id 2=children_loaded 3=expand_filter
    my $store = Gtk3::TreeStore->new(
        'Glib::String', 'Glib::String', 'Glib::Boolean', 'Glib::String',
    );
    my $tree = Gtk3::TreeView->new($store);
    $tree->set_headers_visible(FALSE);
    $tree->append_column(
        Gtk3::TreeViewColumn->new_with_attributes(
            'Name', Gtk3::CellRendererText->new(), text => 0,
        )
    );

    my $sw = Gtk3::ScrolledWindow->new();
    $sw->set_policy('automatic', 'automatic');
    $sw->set_vexpand(TRUE);
    $sw->add($tree);

    my $status = Gtk3::Label->new(q{});
    $status->set_xalign(0.0);

    my $vbox = Gtk3::Box->new('vertical', 6);
    $vbox->set_border_width(12);
    $vbox->pack_start($sw,     TRUE,  TRUE,  0);
    $vbox->pack_start($status, FALSE, FALSE, 0);
    $dlg->get_content_area()->add($vbox);
    $dlg->show_all();

    # Virtual top-level nodes — id is empty so they are not selectable as folders
    my $mf = "mimeType='application/vnd.google-apps.folder' and trashed=false";
    for my $node (
        [ 'My Drive',       "'root' in parents and $mf"  ],
        [ 'Shared with me', "sharedWithMe=true and $mf"  ],
    ) {
        my ($label, $filter) = @$node;
        my $iter = $store->append(undef);
        $store->set($iter, 0, $label, 1, q{}, 2, FALSE, 3, $filter);
        my $ph = $store->append($iter);
        $store->set($ph, 0, "Loading\x{2026}", 1, q{}, 2, FALSE, 3, q{});
    }

    # Enable Select only when a real folder (non-empty id) is highlighted
    $tree->get_selection()->signal_connect(changed => sub {
        my ($sel) = @_;
        my (undef, $iter) = $sel->get_selected();
        my $id = $iter ? $store->get($iter, 1) : q{};
        $dlg->set_response_sensitive('ok', ($id ne q{}) ? TRUE : FALSE);
    });

    # Lazy-load subfolders when a row is expanded.
    # Do NOT remove the placeholder before the API call — removing the only
    # child while the row is expanded causes GTK to auto-collapse it.
    # The placeholder is removed inside _load_drive_children after real
    # children have been appended.
    $tree->signal_connect('row-expanded' => sub {
        my (undef, $iter, undef) = @_;
        return if $store->get($iter, 2);
        $store->set($iter, 2, TRUE);
        my $filter = $store->get($iter, 3);
        $self->_load_drive_children($store, $iter, $filter, $status);
    });

    my $response = $dlg->run();
    my $result;
    if ($response eq 'ok') {
        my (undef, $iter) = $tree->get_selection()->get_selected();
        if ($iter) {
            my ($name, $id) = $store->get($iter, 0, 1);
            $result = { id => $id, name => $name } if $id;
        }
    }
    $dlg->destroy();
    return $result;
}

sub _load_drive_children {
    my ($self, $store, $parent_iter, $filter, $status) = @_;

    my @folders = eval {
        $self->drive->list(
            filter => $filter,
            params => { fields => 'files(id,name)', pageSize => 1000 },
        );
    };
    if ($@) {
        $status->set_text("Error: $@");
        return;
    }

    $status->set_text(q{});
    my $mf = "mimeType='application/vnd.google-apps.folder' and trashed=false";
    for my $f (sort { lc($a->{name}) cmp lc($b->{name}) } @folders) {
        my $iter = $store->append($parent_iter);
        $store->set($iter, 0, $f->{name}, 1, $f->{id}, 2, FALSE,
                    3, "'$f->{id}' in parents and $mf");
        my $ph = $store->append($iter);
        $store->set($ph, 0, "Loading\x{2026}", 1, q{}, 2, FALSE, 3, q{});
    }

    # Remove the placeholder now that real children (or an empty notice) are
    # in place.  Do this after appending so the row is never childless while
    # expanded (which would cause GTK to auto-collapse it).
    my $ph = $store->iter_children($parent_iter);
    if ($ph && $store->get($ph, 1) eq q{}) {
        if (@folders) {
            $store->remove($ph);
        } else {
            # Can't remove the last child; relabel it instead.
            $store->set($ph, 0, '(no subfolders)');
        }
    }
    return;
}

sub _manage_folders_dialog {
    my ($self) = @_;
    my $dlg = Gtk3::Dialog->new_with_buttons(
        'Manage Folders', $self->win,
        [qw/ modal destroy-with-parent /],
        'Close', 'close',
    );
    $dlg->set_default_size(500, 300);

    my $store = Gtk3::ListStore->new('Glib::String', 'Glib::String');
    for my $f (@{ $self->config->music_folders() }) {
        my $iter = $store->append();
        $store->set($iter, 0, $f->{name}, 1, $f->{id});
    }

    my $view = Gtk3::TreeView->new($store);
    my $r = Gtk3::CellRendererText->new();
    $view->append_column(Gtk3::TreeViewColumn->new_with_attributes('Name',      $r, text => 0));
    $view->append_column(Gtk3::TreeViewColumn->new_with_attributes('Drive ID',  $r, text => 1));

    my $sw = Gtk3::ScrolledWindow->new();
    $sw->add($view);

    my $sync_btn = Gtk3::Button->new_with_label('Sync Selected');
    $sync_btn->signal_connect(clicked => sub {
        my $sel  = $view->get_selection();
        my ($model, $iter) = $sel->get_selected();
        return unless $iter;
        my ($name, $id) = ($model->get($iter, 0), $model->get($iter, 1));
        return unless $self->_init_api();
        $self->_show_sync_dialog([{ id => $id, name => $name }]);
    });

    my $remove_btn = Gtk3::Button->new_with_label('Remove Selected');
    $remove_btn->signal_connect(clicked => sub {
        my $sel  = $view->get_selection();
        my ($model, $iter) = $sel->get_selected();
        return unless $iter;
        my $id = $model->get($iter, 1);
        $self->config->remove_music_folder($id);
        $self->config->save();
        $self->db->delete_scan_folder($id);
        $store->remove($iter);
        $self->_load_library();
    });

    my $btn_box = Gtk3::Box->new('horizontal', 4);
    $btn_box->pack_start($sync_btn,   FALSE, FALSE, 0);
    $btn_box->pack_end  ($remove_btn, FALSE, FALSE, 0);

    my $vbox = $dlg->get_content_area();
    $vbox->pack_start($sw,      TRUE,  TRUE,  0);
    $vbox->pack_start($btn_box, FALSE, FALSE, 4);
    $dlg->show_all();
    $dlg->run();
    $dlg->destroy();
    return;
}

1;

__END__

=head1 NAME

App::DrivePlayer::GUI::FolderBrowse - Role for Drive folder browsing dialogs

=head1 DESCRIPTION

A L<Moo::Role> consumed by L<App::DrivePlayer::GUI> that provides dialogs for
adding, browsing, and managing Google Drive music folders.

=cut
