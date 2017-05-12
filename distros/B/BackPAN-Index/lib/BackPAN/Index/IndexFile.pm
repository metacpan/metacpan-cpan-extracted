package BackPAN::Index::IndexFile;

use Mouse;
with 'BackPAN::Index::Role::Log', 'BackPAN::Index::Role::HasCache';

use LWP::Simple qw(getstore head is_success);
use BackPAN::Index::Types;

has index_url =>
  is		=> 'ro',
  isa		=> 'URI',
  coerce	=> 1,
  required	=> 1;

has index_archive =>
  is		=> 'ro',
  isa		=> 'Path::Class::File',
  lazy		=> 1,
  default	=> sub {
      my $self = shift;

      my $path = $self->index_url->path;
      my $file = Path::Class::File->new($path)->basename;
      return Path::Class::File->new($file)->absolute($self->cache->directory);
  };

has index_file =>
  is		=> 'ro',
  isa		=> 'Path::Class::File',
  lazy		=> 1,
  default	=> sub {
      my $self = shift;
      return Path::Class::File->new("backpan-index.txt")->absolute($self->cache->directory);
  };

sub index_archive_mtime {
    my $self = shift;

    my $file = $self->index_archive;
    return -e $file ? $file->stat->mtime : 0;
}

sub index_file_mtime {
    my $self = shift;

    my $file = $self->index_file;
    return -e $file ? $file->stat->mtime : 0;
}

sub index_url_mtime {
    my $self = shift;

    my(undef, undef, $remote_mod_time) = head($self->index_url);
    return $remote_mod_time || 0;
}

sub extract_index_file {
    my $self = shift;

    # Archive::Extract is vulnerable to the ORS.
    local $\;

    require Archive::Extract;

    # Faster.  Say it twice to avoid the "used only once" warning.
    local $Archive::Extract::PREFER_BIN;
    $Archive::Extract::PREFER_BIN = 1;

    my $ae = Archive::Extract->new( archive => $self->index_archive );
    $ae->extract( to => $self->index_file )
      or die "Problem extracting @{[ $self->index_archive ]}: @{[ $ae->error ]}";

    # If the backpan index age is older than the TTL this prevents us
    # from immediately looking again.
    # XXX Should probably use a "last checked" semaphore file
    $self->index_file->touch;

    return;
}

sub get_index {
    my $self = shift;
    
    my $url = $self->index_url;

    $self->_log("Fetching BackPAN index from $url...");
    my $status = getstore($url, $self->index_archive.'');
    die "Error fetching $url: $status" unless is_success($status);
    $self->_log("Done.");

    $self->extract_index_file;

    return;
}

sub should_index_be_updated {
    my $self = shift;

    my $file = $self->index_file;
    return 1 unless -e $file;

    my $local_mod_time = $self->index_file_mtime;
    my $local_age = time - $local_mod_time;
    return 0 unless $local_age > $self->cache->ttl;

    return $self->index_url_mtime > $local_mod_time;
}

1;
