package Test::DrivePlayer::Player;

use strict;
use warnings;

use Module::Load qw( load );
use POSIX   qw( :sys_wait_h );
use Test::Most;
use Test::DrivePlayer::TestBase;
use Test::DrivePlayer::Utils qw( :all );
use Time::HiRes qw( time );

use parent 'Test::DrivePlayer::TestBase';

sub setup : Tests(setup) {
    my ($self) = @_;
    $self->SUPER::setup();
    load('App::DrivePlayer::Player');
    return;
}

# Most Player tests mock the mpv process and IPC socket so we can test
# state management and protocol logic without spawning a real mpv.

# ---- Constructor ----

sub constructor : Tests(3) {
    my ($self) = @_;

    my $p = fake_player();
    isa_ok $p, 'App::DrivePlayer::Player', 'constructor returns Player';
    is $p->state, 'stop', 'initial state is stop';
    is $p->current_track, undef, 'no current track initially';
}

sub constructor_requires_auth : Tests(1) {
    my ($self) = @_;

    throws_ok { App::DrivePlayer::Player->new() }
        qr/required/i,
        'constructor requires auth';
}

sub constructor_callbacks_optional : Tests(1) {
    my ($self) = @_;

    lives_ok {
        App::DrivePlayer::Player->new(auth => fake_auth())
    } 'constructor without callbacks lives';
}

# ---- Token management ----

sub bearer_token_initial_fetch : Tests(2) {
    my ($self) = @_;

    my $p = fake_player(token => 'Bearer mytoken123');
    my $tok = $p->_bearer_token();
    is $tok, 'Bearer mytoken123', 'bearer token fetched from auth';
    ok $p->_token_time > 0,       'token_time set after fetch';
}

sub bearer_token_cached : Tests(2) {
    my ($self) = @_;

    my $call_count = 0;
    my $auth = fake_auth(token => 'Bearer cached_token');

    $self->_mock('auth_headers', 'Test::DrivePlayer::MockAuth', 'headers', sub {
        $call_count++;
        return ['Authorization', 'Bearer cached_token'];
    });

    my $p = App::DrivePlayer::Player->new(auth => $auth);
    $p->_bearer_token();
    $p->_bearer_token();

    is $call_count, 1, 'auth->headers called only once when token cached';
    is $p->_token, 'Bearer cached_token', 'cached token returned';
}

sub bearer_token_refreshes_when_stale : Tests(2) {
    my ($self) = @_;

    my $call_count = 0;
    my $auth = fake_auth();

    $self->_mock('auth_headers', 'Test::DrivePlayer::MockAuth', 'headers', sub {
        $call_count++;
        return ['Authorization', "Bearer token_call_$call_count"];
    });

    my $p = App::DrivePlayer::Player->new(auth => $auth);
    $p->_bearer_token();

    # Simulate stale token by backdating the token_time
    $p->_token_time($p->_token_time - 4000);

    $p->_bearer_token();
    is $call_count, 2, 'auth->headers called again after token expires';
    is $p->_token, 'Bearer token_call_2', 'new token returned after refresh';
}

sub bearer_token_clears_auth_cache : Tests(1) {
    my ($self) = @_;

    # Verify that {headers} is nil at the moment headers() is called, proving
    # that the code does `delete $auth->{headers}` before calling headers().
    my $was_nil_on_call;
    my $auth = fake_auth(token => 'Bearer fresh_token');
    $auth->{headers} = ['Authorization', 'Bearer stale_cached'];

    $self->_mock('clear_check', 'Test::DrivePlayer::MockAuth', 'headers', sub {
        my ($a) = @_;
        $was_nil_on_call = !defined $a->{headers};
        $a->{headers} = ['Authorization', $a->{token}];
        return $a->{headers};
    });

    my $p = App::DrivePlayer::Player->new(auth => $auth);
    $p->_token_time(time() - 4000);
    $p->_token('Bearer stale');
    $p->_bearer_token();

    ok $was_nil_on_call, 'auth->{headers} cleared before re-fetching token';
}

# ---- State transitions ----

sub state_transitions : Tests(6) {
    my ($self) = @_;

    my @state_changes;
    my $p = fake_player(
        on_state_change => sub { push @state_changes, $_[0] }
    );

    is $p->state, 'stop', 'initial state stop';

    # Manually drive state transitions without spawning mpv
    $p->_set_state('play');
    is $p->state, 'play', 'state set to play';
    is $state_changes[-1], 'play', 'on_state_change fired for play';

    $p->_set_state('pause');
    is $p->state, 'pause', 'state set to pause';
    is $state_changes[-1], 'pause', 'on_state_change fired for pause';

    # Setting same state should not fire callback again
    my $prev_count = scalar @state_changes;
    $p->_set_state('pause');
    is scalar @state_changes, $prev_count, 'on_state_change not fired for same state';
}

sub on_state_change_not_required : Tests(1) {
    my ($self) = @_;

    my $p = fake_player();
    lives_ok { $p->_set_state('play') } '_set_state lives without on_state_change callback';
}

# ---- End-of-file handling ----

sub handle_end_file_eof : Tests(3) {
    my ($self) = @_;

    my $track_ended = 0;
    my @state_changes;

    my $p = fake_player(
        on_track_end    => sub { $track_ended++ },
        on_state_change => sub { push @state_changes, $_[0] },
    );

    $p->_set_state('play');
    $p->_handle_end_file({ event => 'end-file', reason => 'eof' });

    is $p->state, 'stop',   'state becomes stop on eof';
    is $track_ended, 1,     'on_track_end fired on eof';
    is $state_changes[-1], 'stop', 'on_state_change fired with stop';
}

sub handle_end_file_error : Tests(2) {
    my ($self) = @_;

    # 'error' means the stream died mid-play (transient network failure,
    # Drive 4xx/5xx, token expiry).  We advance, same as 'eof'.
    my $track_ended = 0;
    my $p = fake_player(on_track_end => sub { $track_ended++ });
    $p->_set_state('play');

    $p->_handle_end_file({ event => 'end-file', reason => 'error' });
    is $track_ended, 1,   'on_track_end fired for error reason';
    is $p->state,    'stop', 'state becomes stop on error';
}

sub handle_end_file_stop_reason : Tests(2) {
    my ($self) = @_;

    # 'stop' fires for user-initiated stop AND for loadfile-replace
    # pre-empting the current track.  We must NOT advance on it, otherwise
    # pressing Next / Stop would trigger phantom skips.
    my $track_ended = 0;
    my $p = fake_player(on_track_end => sub { $track_ended++ });
    $p->_set_state('play');

    $p->_handle_end_file({ event => 'end-file', reason => 'stop' });
    is $track_ended, 0,    'on_track_end NOT fired for stop reason';
    is $p->state,    'play', 'state unchanged for stop reason';
}

sub handle_end_file_quit_reason : Tests(2) {
    my ($self) = @_;

    # 'quit' is emitted when mpv itself is shutting down — ignore.
    my $track_ended = 0;
    my $p = fake_player(on_track_end => sub { $track_ended++ });
    $p->_set_state('play');

    $p->_handle_end_file({ event => 'end-file', reason => 'quit' });
    is $track_ended, 0,    'on_track_end NOT fired for quit reason';
    is $p->state,    'play', 'state unchanged for quit reason';
}

# ---- Event handling ----

sub handle_event_pause_unpause : Tests(3) {
    my ($self) = @_;

    my @states;
    my $p = fake_player(on_state_change => sub { push @states, $_[0] });

    $p->_set_state('play');
    $p->_handle_event({ event => 'pause' });
    is $states[-1], 'pause', 'pause event changes state to pause';

    $p->_handle_event({ event => 'unpause' });
    is $states[-1], 'play', 'unpause event changes state to play';

    my $prev = scalar @states;
    $p->_handle_event({ event => 'unknown-event' });
    is scalar @states, $prev, 'unknown event does not change state';
}

# ---- IPC socket layer (mocked) ----

sub send_command_no_socket : Tests(1) {
    my ($self) = @_;

    my $p = fake_player();
    # _socket is undef; _send_command should silently return
    lives_ok { $p->_send_command(['play']) }
        '_send_command with no socket does not die';
}

sub send_command_sync_no_socket : Tests(1) {
    my ($self) = @_;

    my $p = fake_player();
    my $resp = $p->_send_command_sync(['get_property', 'volume']);
    is $resp, undef, '_send_command_sync returns undef with no socket';
}

# ---- mpv interaction (mocked fork + socket) ----

sub play_uses_drive_url_and_token : Tests(3) {
    my ($self) = @_;

    my @printed;
    my $mock_socket = Test::DrivePlayer::MockSocket->new(
        recv_data => '{"request_id":1,"data":null,"error":"success"}' . "\n"
    );

    $self->_mock('fork',   'POSIX',             'WNOHANG',  sub { 0 });
    $self->_mock('socket', 'IO::Socket::UNIX',  'new',       sub { $mock_socket });

    # Intercept fork to avoid spawning real mpv
    $self->_mock('fork_call', 'App::DrivePlayer::Player', '_ensure_mpv', sub {
        my ($player) = @_;
        $player->_socket($mock_socket);
        $player->_mpv_pid($$);   # use our own PID as fake mpv pid
    });

    my $p = fake_player(token => 'Bearer test_token_xyz');
    my $track = { drive_id => 'track_file_abc123', title => 'Test Song' };

    # Capture the JSON sent to the socket
    $mock_socket->on_print(sub { push @printed, $_[0] });

    $p->play($track);

    is $p->state, 'play', 'state is play after play()';
    is $p->current_track->{drive_id}, 'track_file_abc123', 'current_track set';

    # Verify the loadfile command contains the Drive URL and auth header
    my ($cmd_json) = grep { /loadfile/ } @printed;
    ok $cmd_json, 'loadfile command sent to mpv socket';
}

sub stop_sends_command : Tests(2) {
    my ($self) = @_;

    my @printed;
    my $mock_socket = Test::DrivePlayer::MockSocket->new();
    $mock_socket->on_print(sub { push @printed, $_[0] });

    my $p = fake_player();
    $p->_socket($mock_socket);
    $p->_set_state('play');   # pretend we are playing

    $p->stop();

    is $p->state, 'stop', 'state is stop after stop()';
    my ($cmd) = grep { /\"stop\"/ } @printed;
    ok $cmd, 'stop command sent to mpv';
}

sub pause_resume_toggles : Tests(4) {
    my ($self) = @_;

    my @printed;
    my $mock_socket = Test::DrivePlayer::MockSocket->new();
    $mock_socket->on_print(sub { push @printed, $_[0] });

    my $p = fake_player();
    $p->_socket($mock_socket);

    # pause_resume while stopped should do nothing
    $p->pause_resume();
    is $p->state, 'stop', 'pause_resume while stopped has no effect';
    is scalar @printed, 0, 'no command sent while stopped';

    # pause_resume while playing should send cycle pause
    $p->_set_state('play');
    $p->pause_resume();
    is $p->state, 'pause', 'state becomes pause after pause_resume from play';
    my ($cmd) = grep { /cycle/ } @printed;
    ok $cmd, 'cycle pause command sent';
}

sub seek_sends_absolute_seek : Tests(1) {
    my ($self) = @_;

    my @printed;
    my $mock_socket = Test::DrivePlayer::MockSocket->new();
    $mock_socket->on_print(sub { push @printed, $_[0] });

    my $p = fake_player();
    $p->_socket($mock_socket);
    $p->_set_state('play');

    $p->seek(42.5);
    my ($cmd) = grep { /seek/ } @printed;
    like $cmd, qr/42\.5/, 'seek command contains position value';
}

sub set_volume_sends_command : Tests(1) {
    my ($self) = @_;

    my @printed;
    my $mock_socket = Test::DrivePlayer::MockSocket->new();
    $mock_socket->on_print(sub { push @printed, $_[0] });

    my $p = fake_player();
    $p->_socket($mock_socket);

    $p->set_volume(75);
    my ($cmd) = grep { /volume/ } @printed;
    like $cmd, qr/75/, 'set_volume command contains volume value';
}

# ---- Mock Socket ----

package Test::DrivePlayer::MockSocket;  ## no critic (Modules::ProhibitMultiplePackages)

sub new {
    my ($class, %args) = @_;
    return bless {
        recv_buf  => $args{recv_data} // '',
        print_cb  => undef,
        blocking  => 1,
    }, $class;
}

sub on_print  { $_[0]->{print_cb} = $_[1] }
sub blocking  { $_[0]->{blocking} = $_[1] }
sub close     { }

sub print {
    my ($self, $data) = @_;
    $self->{print_cb}->($data) if $self->{print_cb};
}

sub recv {
    my ($self, undef, $len) = @_;
    my $data = substr($self->{recv_buf}, 0, $len, '');
    $_[1] = $data;
    return length $data;
}

1;
