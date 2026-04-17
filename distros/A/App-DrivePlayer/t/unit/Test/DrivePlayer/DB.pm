package Test::DrivePlayer::DB;

use strict;
use warnings;

use Test::Most;
use Test::DrivePlayer::TestBase;
use Test::DrivePlayer::Utils qw( :all );

use parent 'Test::DrivePlayer::TestBase';

# Each test gets a fresh in-memory-like DB via a temp file.
sub setup : Tests(setup) {
    my ($self) = @_;
    $self->SUPER::setup();
    $self->{db} = fake_db($self->_temp_db_path);
    return;
}

sub db { $_[0]->{db} }

# ---- Schema ----

sub schema_deployed : Tests(3) {
    my ($self) = @_;

    my $dbh = $self->db->schema->storage->dbh;
    my @tables = map { (split /\./, $_)[-1] =~ s/"//gr }
                 $dbh->tables(undef, undef, undef, 'TABLE');

    ok grep({ $_ eq 'scan_folders' } @tables), 'scan_folders table created';
    ok grep({ $_ eq 'folders'      } @tables), 'folders table created';
    ok grep({ $_ eq 'tracks'       } @tables), 'tracks table created';
}

sub second_connect_no_redeploy : Tests(1) {
    my ($self) = @_;

    # Re-connecting to an existing DB must not fail (tables already exist).
    my $db2 = fake_db($self->_temp_db_path);
    ok $db2->track_count >= 0, 'second connection to existing DB succeeds';
}

# ---- scan_folders ----

sub upsert_scan_folder_create : Tests(4) {
    my ($self) = @_;

    my $sf = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    is ref($sf), 'HASH',             'upsert_scan_folder returns hashref';
    ok $sf->{id},                    'returned row has id';
    is $sf->{drive_id}, FAKE_FOLDER_ID,   'drive_id correct';
    is $sf->{name},     FAKE_FOLDER_NAME, 'name correct';
}

sub upsert_scan_folder_update : Tests(2) {
    my ($self) = @_;

    $self->db->upsert_scan_folder(FAKE_FOLDER_ID, 'Original Name');
    my $updated = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, 'Updated Name');
    is $updated->{name}, 'Updated Name', 'name updated on conflict';
    is $self->db->schema->resultset('ScanFolder')->count, 1, 'no duplicate row created';
}

sub get_scan_folder_by_drive_id : Tests(3) {
    my ($self) = @_;

    $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    my $sf = $self->db->get_scan_folder_by_drive_id(FAKE_FOLDER_ID);
    is $sf->{drive_id}, FAKE_FOLDER_ID,   'found by drive_id';
    is $sf->{name},     FAKE_FOLDER_NAME, 'name correct';
    is $self->db->get_scan_folder_by_drive_id('nonexistent'), undef, 'returns undef when not found';
}

sub all_scan_folders_ordering : Tests(2) {
    my ($self) = @_;

    $self->db->upsert_scan_folder('id_z', 'Zzz Folder');
    $self->db->upsert_scan_folder('id_a', 'Aaa Folder');
    $self->db->upsert_scan_folder('id_m', 'Mmm Folder');

    my @folders = $self->db->all_scan_folders;
    is scalar @folders, 3, 'all_scan_folders returns all rows';
    is $folders[0]{name}, 'Aaa Folder', 'scan_folders ordered by name';
}

sub delete_scan_folder_cascade : Tests(3) {
    my ($self) = @_;

    my $sf  = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    my $fld = $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}));
    $self->db->upsert_track(sample_track(folder_id => $fld->{id}));

    is $self->db->track_count, 1, 'track exists before delete';
    $self->db->delete_scan_folder(FAKE_FOLDER_ID);
    is $self->db->schema->resultset('ScanFolder')->count, 0, 'scan_folder deleted';
    is $self->db->track_count, 0, 'tracks cascade-deleted';
}

# ---- folders ----

sub upsert_folder_create : Tests(5) {
    my ($self) = @_;

    my $sf  = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    my $fld = $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}));

    is ref($fld), 'HASH',          'upsert_folder returns hashref';
    ok $fld->{id},                 'returned row has id';
    is $fld->{name},  'Rock',      'name correct';
    ok defined $fld->{path},       'path present';
    is $fld->{scan_folder_id}, $sf->{id}, 'scan_folder_id correct';
}

sub upsert_folder_update : Tests(2) {
    my ($self) = @_;

    my $sf = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}, name => 'OldName'));
    my $updated = $self->db->upsert_folder(
        sample_folder(scan_folder_id => $sf->{id}, name => 'NewName')
    );
    is $updated->{name}, 'NewName', 'folder name updated on conflict';
    is $self->db->schema->resultset('Folder')->count, 1, 'no duplicate folder row';
}

sub get_folder_by_drive_id : Tests(2) {
    my ($self) = @_;

    my $sf = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}));
    my $fld = $self->db->get_folder_by_drive_id('folder_drive_id_rock');
    is $fld->{name}, 'Rock', 'folder found by drive_id';
    is $self->db->get_folder_by_drive_id('nope'), undef, 'returns undef when not found';
}

sub folders_for_scan_folder : Tests(2) {
    my ($self) = @_;

    my $sf  = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    $self->db->upsert_folder(sample_folder(
        scan_folder_id => $sf->{id}, drive_id => 'f1', name => 'Z', path => 'Z'
    ));
    $self->db->upsert_folder(sample_folder(
        scan_folder_id => $sf->{id}, drive_id => 'f2', name => 'A', path => 'A'
    ));

    my @flds = $self->db->folders_for_scan_folder($sf->{id});
    is scalar @flds, 2,      'returns all folders for scan_folder';
    is $flds[0]{name}, 'A',  'folders ordered by path';
}

# ---- tracks ----

sub upsert_track_create : Tests(6) {
    my ($self) = @_;

    my $sf  = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    my $fld = $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}));
    $self->db->upsert_track(sample_track(folder_id => $fld->{id}));

    is $self->db->track_count, 1, 'track inserted';
    my $t = $self->db->get_track_by_drive_id(FAKE_TRACK_ID);
    is ref($t), 'HASH',                   'get_track_by_drive_id returns hashref';
    is $t->{title},       'Bohemian Rhapsody', 'title correct';
    is $t->{artist},      'Queen',             'artist correct';
    is $t->{album},       'A Night at the Opera', 'album correct';
    is $t->{track_number}, 11,                'track_number correct';
}

sub upsert_track_update : Tests(5) {
    my ($self) = @_;

    my $sf  = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    my $fld = $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}));

    # First upsert sets metadata; second upsert (re-scan) should preserve it.
    $self->db->upsert_track(sample_track(folder_id => $fld->{id}, title => 'Old Title'));
    $self->db->upsert_track(sample_track(folder_id => $fld->{id}, title => 'New Title'));

    is $self->db->track_count, 1,          'no duplicate on upsert';
    my $t = $self->db->get_track_by_drive_id(FAKE_TRACK_ID);
    is $t->{title},  'Old Title', 'existing metadata preserved on re-scan';
    is $t->{artist}, 'Queen',     'other fields preserved';

    # A null/placeholder title should be filled in by the scan.
    $self->db->upsert_track_from_metadata(drive_id => FAKE_TRACK_ID, title => undef);
    $self->db->upsert_track(sample_track(folder_id => $fld->{id}, title => 'Filled Title'));
    $t = $self->db->get_track_by_drive_id(FAKE_TRACK_ID);
    is $t->{title},  'Filled Title', 'null title filled in by scan';
    is $t->{artist}, 'Queen',        'artist preserved after null-fill';
}

sub get_track_by_id : Tests(2) {
    my ($self) = @_;

    my $sf  = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    my $fld = $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}));
    $self->db->upsert_track(sample_track(folder_id => $fld->{id}));
    my $by_drive_id = $self->db->get_track_by_drive_id(FAKE_TRACK_ID);

    my $by_id = $self->db->get_track($by_drive_id->{id});
    is $by_id->{drive_id}, FAKE_TRACK_ID, 'get_track by integer id works';
    is $self->db->get_track(99999), undef, 'get_track returns undef for missing id';
}

# ---- Query methods ----

sub _populate_library {
    my ($self) = @_;
    my $sf  = $self->db->upsert_scan_folder(FAKE_FOLDER_ID, FAKE_FOLDER_NAME);
    my $fld = $self->db->upsert_folder(sample_folder(scan_folder_id => $sf->{id}));

    my @tracks = (
        { drive_id => 't1', title => 'Bohemian Rhapsody', artist => 'Queen',
          album => 'A Night at the Opera', track_number => 11, year => 1975,
          mime_type => 'audio/mpeg', folder_id => $fld->{id} },
        { drive_id => 't2', title => 'We Will Rock You', artist => 'Queen',
          album => 'News of the World', track_number => 1, year => 1977,
          mime_type => 'audio/mpeg', folder_id => $fld->{id} },
        { drive_id => 't3', title => 'Stairway to Heaven', artist => 'Led Zeppelin',
          album => 'Led Zeppelin IV', track_number => 4, year => 1971,
          mime_type => 'audio/flac', folder_id => $fld->{id} },
        { drive_id => 't4', title => 'Kashmir', artist => 'Led Zeppelin',
          album => 'Physical Graffiti', track_number => 1, year => 1975,
          mime_type => 'audio/flac', folder_id => $fld->{id} },
    );
    $self->db->upsert_track(%$_) for @tracks;
    return ($sf, $fld);
}

sub all_tracks_ordering : Tests(3) {
    my ($self) = @_;
    $self->_populate_library;

    my @tracks = $self->db->all_tracks;
    is scalar @tracks, 4, 'all_tracks returns all rows';
    # Order: artist, album, track_number, title
    is $tracks[0]{artist}, 'Led Zeppelin', 'first artist alphabetically';
    is $tracks[0]{title},  'Stairway to Heaven', 'first track by album then track_number';
}

sub tracks_by_artist : Tests(3) {
    my ($self) = @_;
    $self->_populate_library;

    my @queen = $self->db->tracks_by_artist('Queen');
    is scalar @queen, 2, 'tracks_by_artist returns matching tracks';
    is $queen[0]{title}, 'Bohemian Rhapsody', 'first Queen track by album+track_number';

    # Case-insensitive
    my @queen_lc = $self->db->tracks_by_artist('queen');
    is scalar @queen_lc, 2, 'tracks_by_artist is case-insensitive';
}

sub tracks_by_album : Tests(3) {
    my ($self) = @_;
    $self->_populate_library;

    my @album = $self->db->tracks_by_album('Led Zeppelin IV');
    is scalar @album, 1, 'tracks_by_album returns matching tracks';
    is $album[0]{title}, 'Stairway to Heaven', 'correct track returned';

    my @album_lc = $self->db->tracks_by_album('led zeppelin iv');
    is scalar @album_lc, 1, 'tracks_by_album is case-insensitive';
}

sub tracks_by_folder : Tests(2) {
    my ($self) = @_;
    my ($sf, $fld) = $self->_populate_library;

    my @tracks = $self->db->tracks_by_folder($fld->{id});
    is scalar @tracks, 4, 'tracks_by_folder returns all tracks in folder';
    is $self->db->tracks_by_folder(99999), 0, 'non-existent folder returns empty list';
}

sub search_tracks : Tests(5) {
    my ($self) = @_;
    $self->_populate_library;

    my @r1 = $self->db->search_tracks('queen');
    is scalar @r1, 2, 'search by artist (lowercase)';

    my @r2 = $self->db->search_tracks('stairway');
    is scalar @r2, 1, 'search by title fragment';
    is $r2[0]{title}, 'Stairway to Heaven', 'correct track found by title';

    my @r3 = $self->db->search_tracks('graffiti');
    is scalar @r3, 1, 'search by album fragment';

    my @r4 = $self->db->search_tracks('zzznomatch');
    is scalar @r4, 0, 'no results for non-matching query';
}

sub all_artists : Tests(3) {
    my ($self) = @_;
    $self->_populate_library;

    my @artists = $self->db->all_artists;
    is scalar @artists, 2, 'all_artists returns distinct artists';
    is $artists[0], 'Led Zeppelin', 'artists ordered alphabetically';
    is $artists[1], 'Queen',        'second artist correct';
}

sub all_albums : Tests(3) {
    my ($self) = @_;
    $self->_populate_library;

    my @albums = $self->db->all_albums;
    is scalar @albums, 4, 'all_albums returns distinct albums';
    # All are distinct here; check ordering
    is $albums[0], 'A Night at the Opera', 'first album alphabetically';
}

sub track_count : Tests(2) {
    my ($self) = @_;
    is $self->db->track_count, 0, 'track_count is 0 for empty DB';
    $self->_populate_library;
    is $self->db->track_count, 4, 'track_count reflects inserted tracks';
}

sub clear_scan_folder_tracks : Tests(3) {
    my ($self) = @_;
    my ($sf) = $self->_populate_library;

    is $self->db->track_count, 4, 'tracks exist before clear';
    $self->db->clear_scan_folder_tracks($sf->{id});
    is $self->db->track_count, 0, 'tracks removed after clear';
    is $self->db->schema->resultset('Folder')->count, 0, 'folders removed after clear';
}

1;
