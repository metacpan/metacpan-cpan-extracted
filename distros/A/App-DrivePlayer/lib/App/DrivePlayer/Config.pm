package App::DrivePlayer::Config;

use App::DrivePlayer::Setup;
use File::Basename  qw( dirname );
use File::Path      qw( make_path );
use YAML::XS        qw( LoadFile DumpFile );

my $DEFAULT_CONFIG_DIR  = "$ENV{HOME}/.config/drive_player";
my $DEFAULT_CONFIG_FILE = "$DEFAULT_CONFIG_DIR/config.yaml";
my $DEFAULT_DATA_DIR    = "$ENV{HOME}/.local/share/drive_player";
my $DEFAULT_DB_PATH     = "$DEFAULT_DATA_DIR/music.db";
my $DEFAULT_LOG_FILE    = "$DEFAULT_DATA_DIR/drive_player.log";

has config_file => (
    is      => 'ro',
    isa     => Str,
    default => sub { $DEFAULT_CONFIG_FILE },
);

# Internal: the parsed YAML data hash
has _data => (
    is      => 'lazy',
    isa     => HashRef,
    builder => '_build_data',
);

sub _build_data {
    my ($self) = @_;
    my $data = $self->_defaults();
    if (-f $self->config_file) {
        my $file = LoadFile($self->config_file);
        # Migrate legacy root-level auth key into google_restapi.auth
        if ($file->{auth} && !($file->{google_restapi} && $file->{google_restapi}{auth})) {
            $file->{google_restapi} //= {};
            $file->{google_restapi}{auth} = delete $file->{auth};
        }
        _merge($data, $file);
    }
    _expand_paths($data, dirname($self->config_file));
    return $data;
}

# Recursively merge $src over $dst (scalar/array values in $src win).
sub _merge {
    my ($dst, $src) = @_;
    for my $key (keys %{ $src }) {
        if (ref $src->{$key} eq 'HASH' && ref $dst->{$key} eq 'HASH') {
            _merge($dst->{$key}, $src->{$key});
        } else {
            $dst->{$key} = $src->{$key};
        }
    }
}

sub _defaults {
    return {
        google_restapi => {
            class => 'OAuth2Client',
            auth  => {
                class         => 'OAuth2Client',
                client_id     => '',
                client_secret => '',
                token_file    => "$DEFAULT_CONFIG_DIR/token.dat",
                scope         => ['https://www.googleapis.com/auth/drive.readonly'],
            },
        },
        music_folders => [],
        database      => { path => $DEFAULT_DB_PATH },
        log_level     => 'WARN',
        log_file      => $DEFAULT_LOG_FILE,
        acoustid_key  => '',
        sheet_id      => '',
    };
}

sub _expand_paths {
    my ($data, $config_dir) = @_;
    for my $key (qw( log_file )) {
        $data->{$key} = _abs_path($data->{$key}, $config_dir) if defined $data->{$key};
    }
    $data->{database}{path} = _abs_path($data->{database}{path}, $config_dir)
        if defined $data->{database}{path};

    # Support auth under google_restapi.auth (preferred) or legacy root auth key
    my $auth = $data->{google_restapi}{auth} // $data->{auth};
    if ($auth && defined $auth->{token_file}) {
        $auth->{token_file} = _abs_path($auth->{token_file}, $config_dir);
    }
}

sub _abs_path {
    my ($path, $config_dir) = @_;
    $path =~ s|^~|$ENV{HOME}|;
    return File::Spec->rel2abs($path, $config_dir) unless File::Spec->file_name_is_absolute($path);
    return $path;
}

sub save {
    my ($self) = @_;
    my $dir = dirname($self->config_file);
    make_path($dir) unless -d $dir;
    DumpFile($self->config_file, $self->_data);
}

sub ensure_dirs {
    my ($self) = @_;
    for my $path ($self->db_path, $self->log_file, $self->token_file) {
        next unless defined $path && $path ne '';
        my $dir = dirname($path);
        make_path($dir) unless -d $dir;
    }
}

# Auth config hashref suitable for Google::RestApi->new(auth => ...)
# Prefers google_restapi.auth; falls back to legacy root-level auth key.
sub auth_config {
    my ($self) = @_;
    return $self->_data->{google_restapi}{auth} // $self->_data->{auth} // {};
}

# Full google_restapi config block for Google::RestApi->new(google_restapi => ...)
sub google_restapi_config { $_[0]->_data->{google_restapi} }

# Music folders: arrayref of { id => '...', name => '...' }
sub music_folders {
    my ($self, $folders) = @_;
    $self->_data->{music_folders} = $folders if defined $folders;
    return $self->_data->{music_folders} // [];
}

sub add_music_folder {
    my ($self, $id, $name) = @_;
    return if grep { $_->{id} eq $id } @{ $self->_data->{music_folders} };
    push @{ $self->_data->{music_folders} }, { id => $id, name => $name };
}

sub remove_music_folder {
    my ($self, $id) = @_;
    $self->_data->{music_folders} = [
        grep { $_->{id} ne $id } @{ $self->_data->{music_folders} }
    ];
}

sub db_path      { $_[0]->_data->{database}{path} }
sub log_level    { $_[0]->_data->{log_level} // 'WARN' }
sub log_file     { $_[0]->_data->{log_file} }
sub token_file   { $_[0]->auth_config->{token_file} }
sub acoustid_key { $_[0]->_data->{acoustid_key} // '' }
sub sheet_id     { $_[0]->_data->{sheet_id}     // '' }

1;

__END__

=head1 NAME

App::DrivePlayer::Config - Load, persist and query DrivePlayer configuration

=head1 SYNOPSIS

  use App::DrivePlayer::Config;

  my $cfg = App::DrivePlayer::Config->new();                      # default path
  my $cfg = App::DrivePlayer::Config->new(config_file => $path);  # explicit path

  # Read settings
  my $auth    = $cfg->auth_config;     # hashref for Google::RestApi->new
  my @folders = @{ $cfg->music_folders };

  # Manage music folders
  $cfg->add_music_folder($drive_id, 'My Music');
  $cfg->remove_music_folder($drive_id);

  $cfg->save;          # write changes back to disk
  $cfg->ensure_dirs;   # create parent directories for db, log, token

=head1 DESCRIPTION

Reads a YAML configuration file and provides typed accessors for every
setting.  Missing files are silently replaced by built-in defaults so the
application works out of the box before the user runs the setup wizard.

Tilde (C<~>) at the start of any path value is expanded to C<$HOME>.

=head1 ATTRIBUTES

=head2 config_file

  is: ro, isa: Str

Path to the YAML configuration file.  Defaults to
F<~/.config/drive_player/config.yaml>.

=head1 METHODS

=head2 new

  my $cfg = App::DrivePlayer::Config->new(%args);

Constructor.  Accepts C<config_file> as an optional named argument.

=head2 auth_config

  my $hashref = $cfg->auth_config;

Returns the C<auth> stanza from the config file as a plain hashref.  Pass
this directly to C<< Google::RestApi->new(auth => ...) >>.

=head2 music_folders

  my $aref   = $cfg->music_folders;
  $cfg->music_folders(\@folders);   # replace all

Getter/setter for the list of configured music folders.  Each element is a
hashref with C<id> (Google Drive folder ID) and C<name> keys.

=head2 add_music_folder

  $cfg->add_music_folder($drive_id, $name);

Appends a new folder to the music folder list.

=head2 remove_music_folder

  $cfg->remove_music_folder($drive_id);

Removes the folder with the given Drive ID from the list.

=head2 db_path

  my $path = $cfg->db_path;

Absolute path to the SQLite database file.

=head2 log_level

  my $level = $cfg->log_level;   # e.g. 'WARN', 'DEBUG'

Log4perl log level string.  Defaults to C<WARN>.

=head2 log_file

  my $path = $cfg->log_file;

Absolute path to the application log file.

=head2 token_file

  my $path = $cfg->token_file;

Absolute path to the OAuth2 token storage file.

=head2 save

  $cfg->save;

Serialises the current configuration to C<config_file>, creating parent
directories as needed.

=head2 ensure_dirs

  $cfg->ensure_dirs;

Creates the parent directories for C<db_path>, C<log_file>, and
C<token_file> if they do not already exist.

=cut
