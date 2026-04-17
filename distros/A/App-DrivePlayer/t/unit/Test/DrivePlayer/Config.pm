package Test::DrivePlayer::Config;

use strict;
use warnings;

use File::Spec;
use Test::Most;
use YAML::XS qw( DumpFile LoadFile );

use Test::DrivePlayer::TestBase;
use Test::DrivePlayer::Utils qw( :all );

use parent 'Test::DrivePlayer::TestBase';

# ---- Constructor ----

sub constructor_defaults : Tests(7) {
    my ($self) = @_;

    # Use a nonexistent path so built-in defaults are always used,
    # regardless of any real config file at the default location.
    my $cfg = fake_config(config_file => '/nonexistent/drive_player/config.yaml');
    isa_ok $cfg, 'App::DrivePlayer::Config', 'Constructor returns';
    ok defined $cfg->config_file,  'config_file is defined';
    ok defined $cfg->db_path,      'db_path is defined';
    ok defined $cfg->log_file,     'log_file is defined';
    ok defined $cfg->log_level,    'log_level is defined';
    ok defined $cfg->token_file,   'token_file is defined';
    is ref($cfg->music_folders), 'ARRAY', 'music_folders returns arrayref';
}

sub constructor_custom_file : Tests(3) {
    my ($self) = @_;

    my $path = $self->_write_yaml('config.yaml', {
        auth => {
            class         => 'OAuth2Client',
            client_id     => 'test_client',
            client_secret => 'test_secret',
            token_file    => '~/.config/drive_player/token.dat',
            scope         => ['https://www.googleapis.com/auth/drive.readonly'],
        },
        music_folders => [{ id => 'folder1', name => 'Music' }],
        database      => { path => '/tmp/test.db' },
        log_level     => 'DEBUG',
        log_file      => '/tmp/test.log',
    });

    my $cfg = fake_config(config_file => $path);
    is $cfg->log_level, 'DEBUG',        'log_level loaded from file';
    is $cfg->auth_config->{client_id}, 'test_client', 'auth config loaded';
    is scalar(@{ $cfg->music_folders }), 1, 'music_folders loaded from file';
}

sub constructor_missing_file : Tests(2) {
    my ($self) = @_;

    my $cfg = fake_config(config_file => '/nonexistent/path/config.yaml');
    ok defined $cfg->db_path,   'db_path has default when file missing';
    is $cfg->log_level, 'WARN', 'log_level defaults to WARN when file missing';
}

# ---- Path expansion ----

sub path_expansion : Tests(3) {
    my ($self) = @_;

    my $path = $self->_write_yaml('config.yaml', {
        auth         => { class => 'OAuth2Client', client_id => 'x', client_secret => 'x',
                          token_file => '~/token.dat', scope => [] },
        database     => { path => '~/music.db' },
        log_file     => '~/drive_player.log',
        music_folders => [],
    });

    my $cfg = fake_config(config_file => $path);
    like $cfg->db_path,    qr{^\Q$ENV{HOME}\E}, 'db_path ~ expanded';
    like $cfg->log_file,   qr{^\Q$ENV{HOME}\E}, 'log_file ~ expanded';
    like $cfg->token_file, qr{^\Q$ENV{HOME}\E}, 'token_file ~ expanded';
}

# ---- auth_config ----

sub auth_config : Tests(3) {
    my ($self) = @_;

    my $cfg = fake_config(config_file => '/nonexistent/drive_player/config.yaml');
    my $auth = $cfg->auth_config();
    is ref($auth), 'HASH',        'auth_config returns hashref';
    ok exists $auth->{class},     'auth_config has class key';
    ok exists $auth->{client_id}, 'auth_config has client_id key';
}

# ---- music_folders ----

sub music_folders_accessor : Tests(4) {
    my ($self) = @_;

    my $cfg = fake_config(config_file => '/nonexistent/drive_player/config.yaml');
    is scalar(@{ $cfg->music_folders }), 0, 'music_folders empty by default';

    $cfg->music_folders([{ id => 'a', name => 'A' }, { id => 'b', name => 'B' }]);
    is scalar(@{ $cfg->music_folders }), 2, 'music_folders setter works';
    is $cfg->music_folders->[0]{id},   'a', 'first folder id correct';
    is $cfg->music_folders->[1]{name}, 'B', 'second folder name correct';
}

sub add_music_folder : Tests(4) {
    my ($self) = @_;

    my $cfg = fake_config(config_file => '/nonexistent/drive_player/config.yaml');
    $cfg->add_music_folder('id1', 'Folder One');
    $cfg->add_music_folder('id2', 'Folder Two');

    my $folders = $cfg->music_folders;
    is scalar(@$folders), 2,           'two folders after two adds';
    is $folders->[0]{id},   'id1',     'first folder id';
    is $folders->[0]{name}, 'Folder One', 'first folder name';
    is $folders->[1]{id},   'id2',     'second folder id';
}

sub remove_music_folder : Tests(3) {
    my ($self) = @_;

    my $cfg = fake_config(config_file => '/nonexistent/drive_player/config.yaml');
    $cfg->add_music_folder('id1', 'Keep');
    $cfg->add_music_folder('id2', 'Remove');
    $cfg->add_music_folder('id3', 'Also Keep');

    $cfg->remove_music_folder('id2');
    my $folders = $cfg->music_folders;
    is scalar(@$folders), 2,       'one folder removed';
    is $folders->[0]{id}, 'id1',   'first folder retained';
    is $folders->[1]{id}, 'id3',   'third folder retained';
}

# ---- save / reload ----

sub save_and_reload : Tests(5) {
    my ($self) = @_;

    my $path = $self->_temp_path('save_test.yaml');
    my $cfg = fake_config(config_file => $path);
    $cfg->add_music_folder('save_id', 'Saved Folder');
    $cfg->auth_config->{client_id} = 'saved_client';
    $cfg->save();

    ok -f $path, 'config file created by save';

    my $reloaded = fake_config(config_file => $path);
    is scalar(@{ $reloaded->music_folders }), 1, 'music_folders persisted';
    is $reloaded->music_folders->[0]{id},   'save_id',       'folder id persisted';
    is $reloaded->music_folders->[0]{name}, 'Saved Folder',  'folder name persisted';
    is $reloaded->auth_config->{client_id}, 'saved_client',  'auth config persisted';
}

# ---- ensure_dirs ----

sub ensure_dirs : Tests(3) {
    my ($self) = @_;

    my $base = $self->_tempdir;
    my $path = $self->_write_yaml('config.yaml', {
        auth         => { class => 'OAuth2Client', client_id => 'x', client_secret => 'x',
                          token_file => "$base/auth/token.dat", scope => [] },
        database     => { path => "$base/data/music.db" },
        log_file     => "$base/logs/app.log",
        music_folders => [],
    });

    my $cfg = fake_config(config_file => $path);
    $cfg->ensure_dirs();

    ok -d "$base/auth",  'auth dir created';
    ok -d "$base/data",  'data dir created';
    ok -d "$base/logs",  'logs dir created';
}

1;
