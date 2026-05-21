package App::DrivePlayer::Player;

# mpv-based audio player using JSON IPC socket for control.
# Streams audio directly from Google Drive using Bearer auth headers.

use App::DrivePlayer::Setup;
use File::Temp      qw( tempfile );
use IO::Socket::UNIX;
use JSON::MaybeXS   qw( encode_json decode_json );
use POSIX           qw( :sys_wait_h );
use Time::HiRes     qw( time sleep );

Readonly my $DRIVE_FILE_URL => 'https://www.googleapis.com/drive/v3/files/%s?alt=media';

my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };
Readonly my $IPC_TIMEOUT    => 0.5;   # seconds to wait for mpv response
Readonly my $TOKEN_MAX_AGE  => 3300;  # refresh bearer token after 55 minutes

has auth => (
    is       => 'ro',
    isa      => HasMethods['headers'],
    required => 1,
);

has on_track_end => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has on_position => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has on_state_change => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

# Private mutable state — use plain attributes with is => 'rw'
has _mpv_pid     => ( is => 'rw', default => sub { undef } );
has _socket      => ( is => 'rw', default => sub { undef } );
has _socket_path => ( is => 'rw', default => sub { undef } );
has _state       => ( is => 'rw', isa => Str,  default => 'stop' );
has _current_track => ( is => 'rw', default => sub { undef } );
has _token       => ( is => 'rw', default => sub { undef } );
has _token_time  => ( is => 'rw', isa => Num,  default => 0 );
has _req_id      => ( is => 'rw', isa => Int,  default => 1 );
has _pending_buf => ( is => 'rw', isa => Str,  default => '' );

# ---- Public API ----

sub play {
    my ($self, $track) = @_;
    $self->_ensure_mpv();
    $self->_current_track($track);

    my $url   = sprintf($DRIVE_FILE_URL, $track->{drive_id});
    my $token = $self->_bearer_token();

    $self->_send_command(['loadfile', $url, 'replace',
        { 'http-header-fields' => "Authorization: $token" }
    ]);
    $self->_set_state('play');
}

sub pause_resume {
    my ($self) = @_;
    return if $self->_state eq 'stop';
    $self->_send_command(['cycle', 'pause']);
    $self->_set_state($self->_state eq 'play' ? 'pause' : 'play');
}

sub stop {
    my ($self) = @_;
    return if $self->_state eq 'stop';
    $self->_send_command(['stop']);
    $self->_set_state('stop');
}

sub seek {
    my ($self, $seconds) = @_;
    return if $self->_state eq 'stop';
    $self->_send_command(['seek', $seconds, 'absolute']);
}

sub set_volume {
    my ($self, $pct) = @_;
    $self->_send_command(['set_property', 'volume', $pct]);
}

sub get_volume {
    my ($self) = @_;
    my $resp = $self->_send_command_sync(['get_property', 'volume']);
    return $resp ? $resp->{data} : 50;
}

sub state         { $_[0]->_state }
sub current_track { $_[0]->_current_track }

# Called by GUI timer to poll position / detect track end
sub poll {
    my ($self) = @_;
    return if $self->_state eq 'stop';
    return unless $self->_socket;

    $self->_drain_events();

    my $pos_resp = $self->_send_command_sync(['get_property', 'time-pos']);
    my $dur_resp = $self->_send_command_sync(['get_property', 'duration']);

    if ($pos_resp && defined $pos_resp->{data} &&
        $dur_resp && defined $dur_resp->{data}) {
        $self->on_position->($pos_resp->{data}, $dur_resp->{data})
            if $self->has_on_position;
    }
}

sub quit {
    my ($self) = @_;
    if ($self->_mpv_pid) {
        eval { $self->_send_command(['quit']) };
        $self->_close_socket();
        # Give mpv a moment to exit cleanly, then force-kill if still running.
        my $deadline = time() + 2;
        while (time() < $deadline) {
            last unless kill(0, $self->_mpv_pid);
            sleep 0.1;
        }
        kill 'KILL', $self->_mpv_pid if kill(0, $self->_mpv_pid);
        waitpid($self->_mpv_pid, 0);
        $self->_mpv_pid(undef);
    } else {
        $self->_close_socket();
    }
    $self->_set_state('stop');
}

# ---- Private helpers ----

sub _bearer_token {
    my ($self) = @_;
    if (!$self->_token || (time() - $self->_token_time) > $TOKEN_MAX_AGE) {
        delete $self->auth->{headers};   # clear cached token to force refresh
        my %h = @{ $self->auth->headers() };
        $self->_token($h{Authorization});
        $self->_token_time(time());
    }
    return $self->_token;
}

sub _ensure_mpv {
    my ($self) = @_;

    if ($self->_mpv_pid && kill(0, $self->_mpv_pid)) {
        return;  # still alive
    }

    $self->_close_socket();

    my (undef, $socket_path) = tempfile("mpv-ipc-XXXXXX", TMPDIR => 1, OPEN => 0);
    $self->_socket_path($socket_path);

    my $pid = fork() // die "fork failed: $!";
    if ($pid == 0) {
        exec(
            'mpv',
            '--idle=yes',
            '--no-video',
            '--no-terminal',
            '--really-quiet',
            "--input-ipc-server=$socket_path",
            '--gapless-audio=weak',
            # Network buffering — reduces stuttering on slow/variable connections
            '--cache=yes',
            '--demuxer-max-bytes=32MiB',   # read-ahead buffer
            '--demuxer-max-back-bytes=8MiB',
            '--cache-pause=yes',           # pause & fill rather than stutter
            '--cache-pause-wait=3',        # seconds of buffer before unpausing
            '--network-timeout=30',
        ) or die "exec mpv failed: $!";
    }

    $self->_mpv_pid($pid);

    my $deadline = time() + 3;
    until (-S $socket_path || time() > $deadline) { sleep 0.1 }
    die "mpv IPC socket never appeared" unless -S $socket_path;

    $self->_open_socket();
}

sub _open_socket {
    my ($self) = @_;
    my $sock = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $self->_socket_path,
    ) or die "Cannot connect to mpv socket: $!";
    $sock->blocking(0);
    $self->_socket($sock);
}

sub _close_socket {
    my ($self) = @_;
    if ($self->_socket) {
        eval { $self->_socket->close() };
        $self->_socket(undef);
    }
    if ($self->_socket_path && -e $self->_socket_path) {
        unlink $self->_socket_path;
        $self->_socket_path(undef);
    }
}

sub _send_command {
    my ($self, $cmd) = @_;
    return unless $self->_socket;
    eval { $self->_socket->print(encode_json({ command => $cmd }) . "\n") };
    $log->warn("IPC send failed: $@") if $@ && $log;
}

sub _send_command_sync {
    my ($self, $cmd) = @_;
    return unless $self->_socket;

    my $id  = $self->_req_id;
    $self->_req_id($id + 1);
    eval { $self->_socket->print(encode_json({ command => $cmd, request_id => $id }) . "\n") };
    if ($@) {
        $log->warn("IPC send_sync failed: $@") if $log;
        return;
    }

    my $deadline = time() + $IPC_TIMEOUT;
    while (time() < $deadline) {
        # First, see if a matching response is already buffered (e.g. read
        # in by an earlier _drain_events / _send_command_sync call).
        my $resp = $self->_consume_buffered_response($id);
        return $resp if $resp;

        my $chunk = '';
        $self->_socket->recv($chunk, 65536);
        if (defined $chunk && length $chunk) {
            $self->_pending_buf($self->_pending_buf . $chunk);
        } else {
            sleep 0.02;
        }
    }
    return;
}

sub _drain_events {
    my ($self) = @_;
    return unless $self->_socket;

    my $chunk = '';
    $self->_socket->recv($chunk, 65536);
    $self->_pending_buf($self->_pending_buf . $chunk)
        if defined $chunk && length $chunk;

    $self->_consume_buffered_response(undef);   # process events, discard any
                                                # stray request responses
}

# Walk through complete lines in _pending_buf, dispatching events and
# returning the first response whose request_id matches $want_id (undef =
# don't match any; just process events).
sub _consume_buffered_response {
    my ($self, $want_id) = @_;
    my $buf = $self->_pending_buf;
    my $matched;

    while ($buf =~ s/^([^\n]+)\n//) {
        my $obj = eval { decode_json($1) };
        next if !$obj || $@;
        if ($obj->{event}) {
            $self->_handle_event($obj);
            next;
        }
        if (defined $want_id && defined $obj->{request_id}
                && $obj->{request_id} == $want_id) {
            $matched = $obj;
            last;
        }
    }
    $self->_pending_buf($buf);
    return $matched;
}

sub _handle_event {
    my ($self, $obj) = @_;
    my $event = $obj->{event} or return;
    if    ($event eq 'end-file') { $self->_handle_end_file($obj) }
    elsif ($event eq 'pause')    { $self->_set_state('pause') }
    elsif ($event eq 'unpause')  { $self->_set_state('play') }
}

sub _handle_end_file {
    my ($self, $obj) = @_;
    my $reason = $obj->{reason} // '';

    # Only 'eof' (track played to the end) and 'error' (stream died: network
    # glitch, 4xx/5xx from Drive, token expiry mid-stream) should advance.
    # 'stop' fires for user-initiated stop AND for loadfile-replace pre-empting
    # the current track, so advancing on it causes skips/double-advances.
    # 'quit' / 'redirect' are housekeeping and should never advance.
    return unless $reason eq 'eof' || $reason eq 'error';

    $self->_set_state('stop');
    $self->on_track_end->() if $self->has_on_track_end;
}

sub _set_state {
    my ($self, $state) = @_;
    return if $self->_state eq $state;
    $self->_state($state);
    $self->on_state_change->($state) if $self->has_on_state_change;
}

1;

__END__

=head1 NAME

App::DrivePlayer::Player - mpv-based audio player that streams from Google Drive

=head1 SYNOPSIS

  use App::DrivePlayer::Player;

  my $player = App::DrivePlayer::Player->new(
      auth             => $auth_obj,      # Google::RestApi::Auth::*
      on_state_change  => sub { my $state = shift; ... },  # 'play','pause','stop'
      on_track_end     => sub { ... },
      on_position      => sub { my ($pos_s, $dur_s) = @_; ... },
  );

  $player->play({ drive_id => $file_id, title => 'Song' });
  $player->pause_resume;
  $player->seek(90);          # jump to 1:30
  $player->set_volume(80);    # 0-100
  $player->stop;
  $player->quit;              # terminate mpv

  # Call periodically from a GUI timer:
  $player->poll;

=head1 DESCRIPTION

Controls an C<mpv> subprocess via its JSON IPC socket.  Audio files are
streamed directly from Google Drive using the Drive media URL with a Bearer
token injected as an HTTP header.  The Bearer token is cached and
automatically refreshed after 55 minutes.

mpv is started lazily on the first call to L</play> and reused for
subsequent tracks.

=head1 ATTRIBUTES

=head2 auth

  is: ro, required: 1

An authentication object with a C<headers()> method returning an arrayref
of the form C<['Authorization', 'Bearer TOKEN']> (e.g.
L<Google::RestApi::Auth::OAuth2Client>).

=head2 on_state_change

  is: ro, isa: CodeRef, optional

Called with the new state string (C<'play'>, C<'pause'>, or C<'stop'>)
whenever the playback state changes.  Not called when the state is set to
its current value.

=head2 on_track_end

  is: ro, isa: CodeRef, optional

Called with no arguments when a track ends naturally (EOF) or is stopped
explicitly.

=head2 on_position

  is: ro, isa: CodeRef, optional

Called by L</poll> with C<($position_seconds, $duration_seconds)> when both
values are available from mpv.

=head1 METHODS

=head2 new

  my $player = App::DrivePlayer::Player->new(%args);

Constructor.  C<auth> is required; all callbacks are optional.

=head2 play

  $player->play(\%track);

Begin playing a track.  C<%track> must contain at least C<drive_id>.
Starts mpv if it is not already running.  Sets state to C<'play'>.

=head2 pause_resume

  $player->pause_resume;

Toggle between C<'play'> and C<'pause'>.  No-op when stopped.

=head2 stop

  $player->stop;

Stop playback and set state to C<'stop'>.  mpv remains running.

=head2 seek

  $player->seek($seconds);

Seek to an absolute position in seconds.  No-op when stopped.

=head2 set_volume

  $player->set_volume($percent);   # 0-100

Set the playback volume.

=head2 get_volume

  my $pct = $player->get_volume;

Return the current volume (0-100).  Returns C<50> if mpv is not responding.

=head2 state

  my $state = $player->state;   # 'play', 'pause', or 'stop'

Return the current playback state.

=head2 current_track

  my $track = $player->current_track;   # hashref or undef

Return the track hashref passed to the most recent L</play> call.

=head2 poll

  $player->poll;

Query mpv for the current playback position and duration, firing the
C<on_position> callback if both are available.  Also drains any pending
mpv events.  Intended to be called from a periodic GUI timer.

=head2 quit

  $player->quit;

Send a quit command to mpv, wait briefly, then SIGTERM it if still
running.  Closes the IPC socket.  Should be called when the application
exits.

=cut
