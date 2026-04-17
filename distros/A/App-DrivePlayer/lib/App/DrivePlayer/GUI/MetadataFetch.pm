package App::DrivePlayer::GUI::MetadataFetch;

# Moo role: background metadata-fetch machinery.

use strict;
use warnings;
use utf8;
use Moo::Role;

use Glib            qw( TRUE FALSE );
use Gtk3            '-init';
use JSON::MaybeXS   qw( encode_json decode_json );
use POSIX           qw( WNOHANG );

use App::DrivePlayer::MetadataFetcher;

my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };

has _meta_watch_id   => ( is => 'rw', default => sub { undef } );
has _meta_pid        => ( is => 'rw', default => sub { undef } );
has _meta_reader     => ( is => 'rw', default => sub { undef } );
has _meta_buf        => ( is => 'rw', default => sub { q{} } );
has _meta_fetch_item => ( is => 'rw' );

sub _toggle_metadata_fetch {
    my ($self) = @_;
    if ($self->_meta_watch_id) {
        $self->_stop_metadata_fetch();
    } else {
        $self->_fetch_all_metadata();
    }
    return;
}

sub _apply_meta_result {
    my ($self, $msg) = @_;
    my $track = $msg->{track};
    my %upd;
    if (my $meta = $msg->{meta}) {
        # Embedded tags are authoritative — overwrite folder-inferred values.
        # Text search / fingerprint only fill in fields that are missing.
        my $trust_tags = ($msg->{source} // '') =~ /embedded tags/;
        for my $key (qw( artist album year genre composer comment track_number )) {
            next if !$trust_tags && $track->{$key} && length $track->{$key};
            $upd{$key} = $meta->{$key} if $meta->{$key};
        }
    }
    if ($msg->{duration_ms} && !$track->{duration_ms}) {
        $upd{duration_ms} = $msg->{duration_ms};
    }
    my $title      = $track->{title} // $msg->{track_id};
    my @meta_fields = grep { $_ ne 'duration_ms' } sort keys %upd;
    if (%upd) {
        my $detail = "source=$msg->{source}";
        $detail .= ' fields=' . join(',', @meta_fields) if @meta_fields;
        $detail .= " duration=$msg->{dur_source}"       if $msg->{dur_source};
        $log->info("Metadata [$title]: $detail") if $log;
        $self->db->update_track_metadata($msg->{track_id}, %upd);
        $self->db->mark_metadata_fetched($msg->{track_id});
        $self->_refresh_track_row($msg->{track_id});
        return 1;
    }
    $log->info("Metadata [$title]: source=$msg->{source} — no new fields") if $log;
    $self->db->mark_metadata_fetched($msg->{track_id});
    return 0;
}

sub _fetch_all_metadata {
    my ($self, $scan_folder_id) = @_;

    my @tracks = $self->db->tracks_needing_metadata($scan_folder_id);
    unless (@tracks) {
        $self->_set_status('All tracks already fetched. Use Library → Reset Metadata Fetch to retry.');
        return;
    }

    # Fetch the bearer token now, before forking, so the child can use it
    # without needing to talk back to the OAuth layer.
    my $token        = $self->_bearer_token() // q{};
    my $acoustid_key = $self->config->acoustid_key();
    my $use_fp       = $acoustid_key
                    && App::DrivePlayer::MetadataFetcher::fpcalc_available()
                    && $token;
    my $use_flac     = App::DrivePlayer::MetadataFetcher::flac_available() && $token;
    my $total = scalar @tracks;

    pipe(my $reader, my $writer) or do { $self->_show_error("pipe: $!"); return };

    my $pid = fork();
    unless (defined $pid) { $self->_show_error("fork: $!"); return }

    if ($pid == 0) {
        # ---- child: HTTP only, never touches GTK ----
        close $reader;
        $writer->autoflush(1);

        my $fetcher = App::DrivePlayer::MetadataFetcher->new(
            acoustid_key => $acoustid_key,
            token_fn     => sub { $token },
        );

        for my $i (0 .. $#tracks) {
            my $track = $tracks[$i];
            my $n     = $i + 1;

            # 1. Try embedded FLAC tags (fast, no network lookup needed if complete)
            my ($meta, $source);
            if ($use_flac && ($track->{mime_type} // '') =~ /flac/i) {
                print {$writer} encode_json({
                    status => 'reading tags', n => $n, total => $total,
                    title  => $track->{title},
                }) . "\n";
                $meta = eval { $fetcher->read_embedded_tags($track->{drive_id}) };
                $source = 'embedded tags' if $meta;
            }

            # 2. Fall back to text search if tags incomplete
            my $tags_complete = $meta && $meta->{title} && $meta->{artist} && $meta->{album};
            if (!$tags_complete) {
                print {$writer} encode_json({
                    status => 'fetching', n => $n, total => $total,
                    title  => $track->{title},
                }) . "\n";
                my $net_meta = eval { $fetcher->fetch(
                    title  => $track->{title},
                    artist => $track->{artist},
                    album  => $track->{album},
                ) };
                if ($net_meta) {
                    $meta   = $meta ? { %$net_meta, %$meta } : $net_meta;
                    $source = $source ? "$source + text search" : 'text search';
                }
            }

            # 3. Fingerprint as last resort
            if (!$tags_complete && !$meta && $use_fp) {
                print {$writer} encode_json({
                    status => 'fingerprinting', n => $n, total => $total,
                    title  => $track->{title},
                }) . "\n";
                $meta = eval { $fetcher->fetch_by_fingerprint(drive_id => $track->{drive_id}) };
                $source = 'fingerprint' if $meta;
            }

            $source //= 'none';

            # 4. Get duration: prefer embedded tags, then ffprobe
            my $duration_ms = $meta ? delete $meta->{duration_ms} : undef;
            my $dur_source;
            if ($duration_ms) {
                $dur_source = 'embedded tags';
            } elsif (!$track->{duration_ms}
                    && App::DrivePlayer::MetadataFetcher::ffprobe_available()) {
                $duration_ms = eval {
                    App::DrivePlayer::MetadataFetcher::probe_duration_ms(
                        undef, $track->{drive_id}, $token,
                    )
                };
                $dur_source = 'ffprobe' if $duration_ms;
            }

            print {$writer} encode_json({
                result      => 1,
                track_id    => $track->{id},
                track       => $track,
                meta        => $meta,
                duration_ms => $duration_ms,
                source      => $source,
                dur_source  => $dur_source,
            }) . "\n";
        }

        print {$writer} encode_json({ done => 1 }) . "\n";
        close $writer;
        POSIX::_exit(0);
    }

    # ---- parent: reads results without blocking ----
    close $writer;
    $self->_meta_pid($pid);
    $self->_meta_reader($reader);
    $self->_meta_buf(q{});

    my $updated = 0;

    my $finish = sub {
        if (my $wid = $self->_meta_watch_id) {
            $self->_meta_watch_id(undef);
            Glib::Source->remove($wid);
        }
        $self->_meta_pid(undef);
        $self->_meta_fetch_item->set_label('Fetch All Metadata');
        close $reader;
        $self->_meta_reader(undef);
        waitpid($pid, 0);
    };

    my $process_msg = sub {
        my ($msg) = @_;
        if ($msg->{status}) {
            $self->_set_status(
                "$msg->{status} $msg->{n}/$msg->{total} ($updated updated): $msg->{title}"
            );
        }
        elsif ($msg->{result}) {
            $updated += $self->_apply_meta_result($msg);
        }
        return;
    };

    my $watch_id = Glib::IO->add_watch(fileno($reader), ['in', 'hup'], sub {
        my (undef, $cond) = @_;

        my $chunk = q{};
        my $bytes = sysread($reader, $chunk, 65536);

        if (!defined $bytes || $bytes == 0) {
            $finish->();
            $self->_set_status("Metadata fetch done — $updated of $total updated.");
            $self->_load_library();
            $self->_auto_sync_to_sheet() if $updated;
            return FALSE;
        }

        my $buf = $self->_meta_buf . $chunk;
        while ($buf =~ s/\A([^\n]+)\n//) {
            my $msg = eval { decode_json($1) } or next;
            $process_msg->($msg);
        }
        $self->_meta_buf($buf);

        return TRUE;
    });

    $self->_meta_watch_id($watch_id);
    $self->_meta_fetch_item->set_label('Stop Metadata Fetch');
    $self->_set_status("Fetching metadata for $total tracks in background…");
    return;
}

sub _stop_metadata_fetch {
    my ($self) = @_;
    return unless $self->_meta_watch_id;
    Glib::Source->remove($self->_meta_watch_id);
    $self->_meta_watch_id(undef);
    $self->_meta_fetch_item->set_label('Fetch All Metadata');
    if (my $pid = $self->_meta_pid) {
        kill 'TERM', $pid;
        waitpid($pid, 0);
        $self->_meta_pid(undef);
    }
    # Drain any result messages the child had already written before dying
    if (my $reader = $self->_meta_reader) {
        my $buf = $self->_meta_buf;
        my $chunk = q{};
        while (sysread($reader, $chunk, 65536)) {
            $buf .= $chunk;
        }
        while ($buf =~ s/\A([^\n]+)\n//) {
            my $msg = eval { decode_json($1) } or next;
            next unless $msg->{result};
            $self->_apply_meta_result($msg);
        }
        close $reader;
        $self->_meta_reader(undef);
        $self->_meta_buf(q{});
    }
    $self->_set_status('Metadata fetch stopped. Progress saved — will resume here next time.');
    return;
}

sub _reset_metadata_fetch {
    my ($self) = @_;
    if ($self->_meta_watch_id) {
        $self->_show_error('Cannot reset while a fetch is in progress.');
        return;
    }
    $self->db->reset_metadata_fetched();
    $self->_set_status('Metadata fetch progress reset — all tracks will be retried.');
    return;
}

sub _retry_incomplete_metadata {
    my ($self) = @_;
    if ($self->_meta_watch_id) {
        $self->_show_error('Cannot reset while a fetch is in progress.');
        return;
    }
    $self->db->reset_metadata_fetched_incomplete();
    $self->_fetch_all_metadata();
    return;
}

sub _fetch_track_metadata {
    my ($self, $track) = @_;

    my $yield = sub { Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending() };

    $self->_set_status('Looking up metadata…');
    $yield->();

    my $fetcher = App::DrivePlayer::MetadataFetcher->new(
        yield        => $yield,
        acoustid_key => $self->config->acoustid_key(),
        token_fn     => sub { $self->_bearer_token() },
    );
    my $meta = $fetcher->fetch(
        title  => $track->{title},
        artist => $track->{artist},
        album  => $track->{album},
    );

    unless ($meta) {
        my $key      = $self->config->acoustid_key();
        my $have_fp  = App::DrivePlayer::MetadataFetcher::fpcalc_available();

        if (!$key) {
            $self->_set_status('Text search: no match. Fingerprinting skipped: no AcoustID key set.');
            return;
        }
        if (!$have_fp) {
            $self->_set_status('Text search: no match. Fingerprinting skipped: fpcalc not installed.');
            return;
        }
        unless ($self->_init_api()) {
            $self->_set_status('Text search: no match. Fingerprinting skipped: Google API not initialised.');
            return;
        }

        $self->_set_status('Text search: no match. Downloading audio for fingerprinting…');
        $yield->();
        my $err;
        $meta = eval { $fetcher->fetch_by_fingerprint(drive_id => $track->{drive_id}) };
        $err  = $@ if $@;

        unless ($meta) {
            my $reason = $err ? "error: $err"
                               : $fetcher->last_fp_stage() // 'no match found';
            $self->_set_status("Fingerprint lookup: $reason");
            return;
        }
    }

    my %merged = (%$track, %$meta);
    $self->_edit_metadata_dialog(\%merged);
    $self->_set_status(q{});
    return;
}

1;

__END__

=head1 NAME

App::DrivePlayer::GUI::MetadataFetch - Role for background metadata fetching

=head1 DESCRIPTION

A L<Moo::Role> consumed by L<App::DrivePlayer::GUI> that handles background
metadata fetching via a forked child process.

=cut
