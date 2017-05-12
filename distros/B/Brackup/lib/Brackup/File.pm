package Brackup::File;
# "everything is a file"
#  ... this class includes symlinks and directories

use strict;
use warnings;
use Carp qw(croak);
use File::stat ();
use Fcntl qw(S_ISREG S_ISDIR S_ISLNK S_ISFIFO O_RDONLY);
use Digest::SHA1;
use String::Escape qw(printable);
use Brackup::PositionedChunk;
use Brackup::Chunker::Default;
use Brackup::Chunker::MP3;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {}, $class;

    $self->{root} = delete $opts{root};
    $self->{path} = delete $opts{path};
    $self->{stat} = delete $opts{stat};  # File::stat object
    croak("Unknown options: " . join(', ', keys %opts)) if %opts;

    die "No root object provided." unless $self->{root} && $self->{root}->isa("Brackup::Root");
    die "No path provided." unless defined($self->{path});  # note: permit "0"
    $self->{path} =~ s!^\./!!;

    return $self;
}

sub root {
    my $self = shift;
    return $self->{root};
}

# returns File::stat object
sub stat {
    my $self = shift;
    return $self->{stat} if $self->{stat};
    my $path = $self->fullpath;
    my $stat = File::stat::lstat($path);
    return $self->{stat} = $stat;
}

sub size {
    my $self = shift;
    return $self->stat->size;
}

sub is_dir {
    my $self = shift;
    return S_ISDIR($self->stat->mode);
}

sub is_link {
    my $self = shift;
    my $result = eval { S_ISLNK($self->stat->mode) };
    $result = -l $self->fullpath unless defined($result);
    return $result;
}

sub is_file {
    my $self = shift;
    return S_ISREG($self->stat->mode);
}

sub is_fifo {
    my $self = shift;
    return S_ISFIFO($self->stat->mode);
}

# Returns file type like find's -type
sub type {
    my $self = shift;
    return "f" if $self->is_file;
    return "d" if $self->is_dir;
    return "l" if $self->is_link;
    return "p" if $self->is_fifo;
    return "";
}

sub fullpath {
    my $self = shift;
    return $self->{root}->path . "/" . $self->{path};
}

# a scalar that hopefully uniquely represents a single version of a file in time.
sub cachekey {
    my $self = shift;
    my $st   = $self->stat;
    return "[" . $self->{root}->name . "]" . $self->{path} . ":" . join(",", $st->ctime, $st->mtime, $st->size, $st->ino);
}

# Returns the appropriate FileChunker class for the provided file's
# type.  In most cases this FileChunker will be very dumb, just making
# equal-sized chunks for, say, 5MB, but in specialized cases (like mp3
# files), the chunks will be one (or two) small ones for the ID3v1/v2
# chunks, and one big chunk for the audio bytes (which might be cut
# into its own small chunks).  This way the mp3 metadata can be
# changed without needing to back up the entire file again ... just
# the changed metadata.
sub file_chunker {
    my $self = shift;
    if ($self->{path} =~ /\.mp3$/i && $self->{root}->smart_mp3_chunking) {
        return "Brackup::Chunker::MP3";
    }
    return "Brackup::Chunker::Default";
}

sub chunks {
    my $self = shift;
    # memoized:
    return @{ $self->{chunks} } if $self->{chunks};

    # non-files don't have chunks
    if (!$self->is_file) {
        $self->{chunks} = [];
        return ();
    }

    # Get the appropriate FileChunker for this file type,
    # then pass ourselves to it to get our chunks.
    my @chunk_list = $self->file_chunker->chunks($self);

    $self->{chunks} = \@chunk_list;
    return @chunk_list;
}

sub full_digest {
    my $self = shift;
    return $self->{_full_digest} ||= $self->_calc_full_digest;
}

sub _calc_full_digest {
    my $self = shift;
    return "" unless $self->is_file;

    my $cache = $self->{root}->digest_cache;
    my $key   = $self->cachekey;

    my $dig = $cache->get($key);
    return $dig if $dig;

    # legacy migration thing... we used to more often store
    # the chunk digests, not the file digests.  so try that
    # first...
    if ($self->chunks == 1) {
        my ($chunk) = $self->chunks;
        $dig = $cache->get($chunk->cachekey);
    }

    unless ($dig) {
        my $sha1 = Digest::SHA1->new;
        my $path = $self->fullpath;
        sysopen(my $fh, $path, O_RDONLY) or die "Failed to open $path: $!";
        binmode($fh);
        $sha1->addfile($fh);
        close($fh);

        $dig = "sha1:" . $sha1->hexdigest;
    }

    $cache->set($key => $dig);
    return $dig;
}

sub link_target {
    my $self = shift;
    return $self->{linktarget} if $self->{linktarget};
    return undef unless $self->is_link;
    return $self->{linktarget} = readlink($self->fullpath);
}

sub path {
    my $self = shift;
    return $self->{path};
}

sub as_string {
    my $self = shift;
    my $type = $self->type;
    return "[" . $self->{root}->as_string . "] t=$type $self->{path}";
}

sub mode {
    my $self = shift;
    return sprintf('%#o', $self->stat->mode & 0777);
}

sub uid {
    my $self = shift;
    return $self->stat->uid;
}

sub gid {
    my $self = shift;
    return $self->stat->gid;
}

sub as_rfc822 {
    my ($self, $schunk_list, $backup) = @_;
    my $ret = "";
    my $set = sub {
        my ($key, $val) = @_;
        return unless length $val;
        $ret .= "$key: $val\n";
    };
    my $st = $self->stat;

    $set->("Path", printable($self->{path}));
    my $type = $self->type;
    if ($self->is_file) {
        my $size = $self->size;
        $set->("Size", $size);
        $set->("Digest", $self->full_digest) if $size;
    } else {
        $set->("Type", $type);
        if ($self->is_link) {
            $set->("Link", $self->link_target);
        }
    }
    $set->("Chunks", join("\n ", map { $_->to_meta } @$schunk_list));

    unless ($self->is_link) {
        $set->("Mtime", $st->mtime);
        $set->("Atime", $st->atime) unless $self->root->noatime;

        my $mode = $self->mode;
        unless (($type eq "d" && $mode eq $backup->default_directory_mode) ||
                ($type eq "f" && $mode eq $backup->default_file_mode)) {
            $set->("Mode", $mode);
        }
    }

    my $uid = $self->uid;
    unless ($uid eq $backup->default_uid) {
      $set->("UID", $uid);
    }
    my $gid = $self->gid;
    unless ($gid eq $backup->default_gid) {
      $set->("GID", $gid);
    }

    return $ret . "\n";
}

1;
