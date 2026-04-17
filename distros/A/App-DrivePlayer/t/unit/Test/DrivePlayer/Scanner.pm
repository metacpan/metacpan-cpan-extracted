package Test::DrivePlayer::Scanner;

use strict;
use warnings;
use utf8;

use Module::Load qw( load );
use Test::Most;
use Test::DrivePlayer::TestBase;
use Test::DrivePlayer::Utils qw( :all );

use parent 'Test::DrivePlayer::TestBase';

sub setup : Tests(setup) {
    my ($self) = @_;
    $self->SUPER::setup();
    Module::Load::load('App::DrivePlayer::Scanner');
    $self->{db} = fake_db($self->_temp_db_path);
    return;
}

sub db { $_[0]->{db} }

# ---- _parse_filename (internal function, tested directly) ----

sub parse_filename_artist_title : Tests(4) {
    my ($self) = @_;

    my ($title, $artist) = App::DrivePlayer::Scanner::_parse_filename('Queen - Bohemian Rhapsody.mp3');
    is $title,  'Bohemian Rhapsody', 'artist-title: title correct';
    is $artist, 'Queen',             'artist-title: artist correct';

    my ($title2, $artist2) = App::DrivePlayer::Scanner::_parse_filename('Led Zeppelin – Kashmir.flac');
    is $title2,  'Kashmir',        'em-dash separator works: title';
    is $artist2, 'Led Zeppelin',   'em-dash separator works: artist';
}

sub parse_filename_track_artist_title : Tests(4) {
    my ($self) = @_;

    my ($title, $artist, undef, $track_num) =
        App::DrivePlayer::Scanner::_parse_filename('01 - Queen - Bohemian Rhapsody.mp3');
    is $title,     'Bohemian Rhapsody', 'track-artist-title: title correct';
    is $artist,    'Queen',             'track-artist-title: artist correct';
    is $track_num, 1,                   'track-artist-title: track_number correct';

    (undef, undef, undef, my $tn2) =
        App::DrivePlayer::Scanner::_parse_filename('11. Artist - Title.mp3');
    is $tn2, 11, 'dot separator for track number';
}

sub parse_filename_track_title : Tests(3) {
    my ($self) = @_;

    my ($title, $artist, undef, $track_num) =
        App::DrivePlayer::Scanner::_parse_filename('03 - Stairway to Heaven.flac');
    is $title,     'Stairway to Heaven', 'track-title: title correct';
    is $artist,    undef,                'track-title: artist is undef';
    is $track_num, 3,                    'track-title: track_number correct';
}

sub parse_filename_title_only : Tests(3) {
    my ($self) = @_;

    my ($title, $artist, undef, $track_num) =
        App::DrivePlayer::Scanner::_parse_filename('Untitled Track.ogg');
    is $title,     'Untitled Track', 'title-only: title correct';
    is $artist,    undef,            'title-only: artist is undef';
    is $track_num, undef,            'title-only: track_number is undef';
}

sub parse_filename_year_extraction : Tests(2) {
    my ($self) = @_;

    my ($title, undef, undef, undef, $year) =
        App::DrivePlayer::Scanner::_parse_filename('Bohemian Rhapsody (1975).mp3');
    is $title, 'Bohemian Rhapsody', 'year stripped from title';
    is $year,  1975,                'year extracted correctly';
}

sub parse_filename_year_bracket : Tests(2) {
    my ($self) = @_;

    my ($title, undef, undef, undef, $year) =
        App::DrivePlayer::Scanner::_parse_filename('Kashmir [1975].flac');
    is $title, 'Kashmir', 'bracket year stripped from title';
    is $year,  1975,      'bracket year extracted';
}

sub parse_filename_strips_extension : Tests(1) {
    my ($self) = @_;

    my ($title) = App::DrivePlayer::Scanner::_parse_filename('My Song.flac');
    is $title, 'My Song', 'extension stripped';
}

# ---- scan_folder ----

sub scan_folder_basic : Tests(5) {
    my ($self) = @_;

    # Two audio files in the root folder, no subfolders
    my $drive = fake_drive(
        responses => [
            [
                { id => 'tf1', name => 'Queen - Bohemian Rhapsody.mp3',
                  mimeType => 'audio/mpeg', size => 5_000_000, modifiedTime => '2024-01-01T00:00:00Z' },
                { id => 'tf2', name => 'Queen - We Will Rock You.mp3',
                  mimeType => 'audio/mpeg', size => 3_000_000, modifiedTime => '2024-01-01T00:00:00Z' },
            ],
        ]
    );

    my $progress_msgs = [];
    my $found_tracks  = [];
    my $scanner = fake_scanner(
        drive         => $drive,
        db            => $self->db,
        on_progress   => sub { push @$progress_msgs, $_[0] },
        on_track_found => sub { push @$found_tracks, $_[0] },
    );

    $scanner->scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);

    is $self->db->track_count, 2, 'two tracks inserted';
    is scalar @$found_tracks,  2, 'on_track_found called twice';
    ok scalar @$progress_msgs > 0, 'progress callback called at least once';
    ok grep({ $_->{title} eq 'Bohemian Rhapsody' } @$found_tracks), 'track 1 found';
    ok grep({ $_->{title} eq 'We Will Rock You'  } @$found_tracks), 'track 2 found';
}

sub scan_folder_recursive : Tests(4) {
    my ($self) = @_;

    # Root folder has one subfolder and one audio file;
    # subfolder has two audio files.
    my $drive = fake_drive(
        responses => [
            # root listing
            [
                { id => 'sub1', name => 'Rock',
                  mimeType => 'application/vnd.google-apps.folder' },
                { id => 'tf0', name => '00 - Intro.mp3',
                  mimeType => 'audio/mpeg', size => 1_000_000, modifiedTime => '2024-01-01T00:00:00Z' },
            ],
            # subfolder listing
            [
                { id => 'tf1', name => 'Stairway to Heaven.flac',
                  mimeType => 'audio/flac', size => 40_000_000, modifiedTime => '2024-01-01T00:00:00Z' },
                { id => 'tf2', name => 'Kashmir.flac',
                  mimeType => 'audio/flac', size => 35_000_000, modifiedTime => '2024-01-01T00:00:00Z' },
            ],
        ]
    );

    my $scanner = fake_scanner(drive => $drive, db => $self->db);
    $scanner->scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);

    is $self->db->track_count, 3, 'three tracks found across root and subfolder';
    is $drive->call_count, 2, 'drive->list called once per folder';

    my @folders = $self->db->schema->resultset('Folder')->all;
    is scalar @folders, 2, 'root folder and subfolder recorded';

    my ($sub) = grep { $_->name eq 'Rock' } @folders;
    my @sub_tracks = $self->db->tracks_by_folder($sub->id);
    is scalar @sub_tracks, 2, 'two tracks in subfolder';
}

sub scan_folder_path_based_metadata : Tests(3) {
    my ($self) = @_;

    # Folder path: "Music/The Beatles/Abbey Road/track.mp3"
    # Scanner should infer artist=The Beatles, album=Abbey Road
    my $drive = fake_drive(
        responses => [
            # root = "Music"
            [{ id => 'artist_dir', name => 'The Beatles',
               mimeType => 'application/vnd.google-apps.folder' }],
            # artist dir
            [{ id => 'album_dir', name => 'Abbey Road',
               mimeType => 'application/vnd.google-apps.folder' }],
            # album dir
            [{ id => 'tf1', name => '02 - Come Together.mp3',
               mimeType => 'audio/mpeg', size => 4_500_000, modifiedTime => '2024-01-01T00:00:00Z' }],
        ]
    );

    my $scanner = fake_scanner(drive => $drive, db => $self->db);
    $scanner->scan_folder(FAKE_FOLDER_ID, 'Music');

    my ($t) = $self->db->all_tracks;
    is $t->{title},  'Come Together',  'title parsed from filename';
    is $t->{artist}, 'The Beatles',    'artist inferred from folder path';
    is $t->{album},  'Abbey Road',     'album inferred from folder path';
}

sub scan_folder_filters_non_audio : Tests(2) {
    my ($self) = @_;

    my $drive = fake_drive(
        responses => [[
            { id => 'tf1', name => 'song.mp3', mimeType => 'audio/mpeg',
              size => 1_000, modifiedTime => '2024-01-01T00:00:00Z' },
            { id => 'if1', name => 'cover.jpg', mimeType => 'image/jpeg',
              size => 500, modifiedTime => '2024-01-01T00:00:00Z' },
            { id => 'df1', name => 'notes.txt', mimeType => 'text/plain',
              size => 100, modifiedTime => '2024-01-01T00:00:00Z' },
        ]]
    );

    my $scanner = fake_scanner(drive => $drive, db => $self->db);
    $scanner->scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);

    is $self->db->track_count, 1, 'only audio file inserted';
    is $self->db->get_track_by_drive_id('tf1')->{title}, 'song', 'audio track title correct';
}

sub scan_folder_fresh_rescan : Tests(3) {
    my ($self) = @_;

    # First scan: 2 tracks
    my $drive = fake_drive(
        responses => [[
            { id => 'tf1', name => 'Old Track.mp3', mimeType => 'audio/mpeg',
              size => 1000, modifiedTime => '2024-01-01T00:00:00Z' },
            { id => 'tf2', name => 'Another Track.mp3', mimeType => 'audio/mpeg',
              size => 2000, modifiedTime => '2024-01-01T00:00:00Z' },
        ]]
    );
    my $scanner = fake_scanner(drive => $drive, db => $self->db);
    $scanner->scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    is $self->db->track_count, 2, 'two tracks after first scan';

    # Second scan with different content
    my $drive2 = fake_drive(
        responses => [[
            { id => 'tf3', name => 'New Track.mp3', mimeType => 'audio/mpeg',
              size => 3000, modifiedTime => '2024-02-01T00:00:00Z' },
        ]]
    );
    my $scanner2 = fake_scanner(drive => $drive2, db => $self->db);
    $scanner2->scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    is $self->db->track_count, 1, 'old tracks replaced on rescan';
    is $self->db->get_track_by_drive_id('tf3')->{title}, 'New Track', 'new track present';
}

sub scan_folder_stop : Tests(2) {
    my ($self) = @_;

    # Root has a subfolder; stopping in on_progress prevents drive->list being called
    my $drive = fake_drive(
        responses => [
            # This response should never be consumed because we stop before listing
            [
                { id => 'sub1', name => 'Sub',
                  mimeType => 'application/vnd.google-apps.folder' },
            ],
        ]
    );

    my $scanner;
    $scanner = fake_scanner(
        drive       => $drive,
        db          => $self->db,
        on_progress => sub { $scanner->stop },   # stop as soon as scanning starts
    );

    $scanner->scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);

    is $self->db->track_count, 0, 'no tracks inserted when stopped via progress callback';
    is $drive->call_count, 0,    'drive not queried after stop in progress callback';
}

sub scan_folder_drive_error : Tests(1) {
    my ($self) = @_;

    # MockDrive will die when given a string response
    my $drive = fake_drive(
        responses => [ 'API Error: rate limit exceeded' ]
    );

    my @errors;
    my $scanner = fake_scanner(
        drive       => $drive,
        db          => $self->db,
        on_progress => sub { push @errors, $_[0] if $_[0] =~ /Error/i },
    );

    lives_ok { $scanner->scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME) }
        'scan_folder survives a Drive API error';
}

1;
