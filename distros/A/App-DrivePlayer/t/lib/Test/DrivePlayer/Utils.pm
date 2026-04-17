package Test::DrivePlayer::Utils;

# Factory functions and shared fixtures for DrivePlayer tests.

use strict;
use warnings;

use File::Spec;
use Module::Load qw( load );

use Exporter qw( import );
our @EXPORT_OK = qw(
    fake_config   fake_db   fake_scanner   fake_player
    fake_drive    fake_auth
    sample_track  sample_folder  sample_scan_folder
    FAKE_FOLDER_ID FAKE_FOLDER_NAME
    FAKE_DRIVE_ID  FAKE_TRACK_ID
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant FAKE_FOLDER_ID   => 'fake_root_folder_id';
use constant FAKE_FOLDER_NAME => 'Test Music';
use constant FAKE_DRIVE_ID    => 'fake_track_drive_id_001';
use constant FAKE_TRACK_ID    => 'fake_track_drive_id_001';

# ---- Factory functions ----

sub fake_config {
    my (%args) = @_;
    load('App::DrivePlayer::Config');
    return App::DrivePlayer::Config->new(%args);
}

sub fake_db {
    my ($path) = @_;
    $path //= do {
        require File::Temp;
        File::Temp::tempfile(SUFFIX => '.db', UNLINK => 1);
    };
    load('App::DrivePlayer::DB');
    return App::DrivePlayer::DB->new(path => $path);
}

sub fake_drive {
    my (%responses) = @_;
    return Test::DrivePlayer::MockDrive->new(%responses);
}

sub fake_auth {
    my (%args) = @_;
    return Test::DrivePlayer::MockAuth->new(%args);
}

sub fake_scanner {
    my (%args) = @_;
    load('App::DrivePlayer::Scanner');
    return App::DrivePlayer::Scanner->new(%args);
}

sub fake_player {
    my (%args) = @_;
    load('App::DrivePlayer::Player');
    return App::DrivePlayer::Player->new(
        auth => fake_auth(%args),
        %args,
    );
}

# ---- Sample data ----

sub sample_scan_folder {
    return (
        drive_id => FAKE_FOLDER_ID,
        name     => FAKE_FOLDER_NAME,
    );
}

sub sample_folder {
    my (%overrides) = @_;
    return (
        drive_id        => 'folder_drive_id_rock',
        name            => 'Rock',
        parent_drive_id => FAKE_FOLDER_ID,
        path            => FAKE_FOLDER_NAME . '/Rock',
        scan_folder_id  => 1,
        %overrides,
    );
}

sub sample_track {
    my (%overrides) = @_;
    return (
        drive_id      => FAKE_TRACK_ID,
        title         => 'Bohemian Rhapsody',
        artist        => 'Queen',
        album         => 'A Night at the Opera',
        track_number  => 11,
        year          => 1975,
        duration_ms   => 354000,
        size          => 8_500_000,
        mime_type     => 'audio/mpeg',
        modified_time => '2024-01-01T00:00:00Z',
        folder_id     => 1,
        folder_path   => FAKE_FOLDER_NAME . '/Rock',
        %overrides,
    );
}

# ---- Mock Drive object ----

package Test::DrivePlayer::MockDrive;

sub new {
    my ($class, %args) = @_;
    return bless {
        responses => $args{responses} // [],  # arrayref of arrayrefs to return per call
        call_log  => [],
    }, $class;
}

sub list {
    my ($self, %args) = @_;
    push @{ $self->{call_log} }, { filter => $args{filter}, params => $args{params} };
    my $resp = shift @{ $self->{responses} };
    die "MockDrive: no response queued for filter '$args{filter}'" unless defined $resp;
    die $resp if !ref($resp);   # die with string to simulate API error
    return @$resp;
}

sub call_log  { @{ $_[0]->{call_log} } }
sub call_count { scalar @{ $_[0]->{call_log} } }

# ---- Mock Auth object ----

package Test::DrivePlayer::MockAuth;

sub new {
    my ($class, %args) = @_;
    return bless {
        token     => $args{token} // 'Bearer fake_access_token_12345',
        headers   => undef,
    }, $class;
}

sub headers {
    my ($self) = @_;
    $self->{headers} = [ Authorization => $self->{token} ];
    return $self->{headers};
}

1;
