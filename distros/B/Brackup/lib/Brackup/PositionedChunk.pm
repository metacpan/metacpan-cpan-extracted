package Brackup::PositionedChunk;

use strict;
use warnings;
use Carp qw(croak);
use Brackup::Util qw(io_sha1);
use IO::File;
use IO::InnerFile;
use Fcntl qw(SEEK_SET);

use fields (
            'file',     # the Brackup::File object
            'offset',   # offset within said file
            'length',   # length of data
            '_raw_digest',
            '_raw_chunkref',
            );

sub new {
    my ($class, %opts) = @_;
    my $self = ref $class ? $class : fields::new($class);

    $self->{file}   = delete $opts{'file'};    # Brackup::File object
    $self->{offset} = delete $opts{'offset'};
    $self->{length} = delete $opts{'length'};

    croak("Unknown options: " . join(', ', keys %opts)) if %opts;
    croak("offset not numeric") unless $self->{offset} =~ /^\d+$/;
    croak("length not numeric") unless $self->{length} =~ /^\d+$/;
    return $self;
}

sub as_string {
    my $self = shift;
    return $self->{file}->as_string . "{off=$self->{offset},len=$self->{length}}";
}

# the original length, pre-encryption
sub length {
    my $self = shift;
    return $self->{length};
}

sub offset {
    my $self = shift;
    return $self->{offset};
}

sub file {
    my $self = shift;
    return $self->{file};
}

sub root {
    my $self = shift;
    return $self->file->root;
}

sub raw_digest {
    my $self = shift;
    return $self->{_raw_digest} ||= $self->_calc_raw_digest;
}

sub _calc_raw_digest {
    my $self = shift;

    my $n_chunks = $self->{file}->chunks
        or die "zero chunks?";
    if ($n_chunks == 1) {
        # don't calculate this chunk's digest.. it's the same as our
        # file's digest, since this chunk spans the entire file.
        die "ASSERT" unless $self->length == $self->{file}->size;
        return $self->{file}->full_digest;
    }

    my $cache = $self->root->digest_cache;
    my $key   = $self->cachekey;
    my $dig;

    if ($dig = $cache->get($key)) {
        return $self->{_raw_digest} = $dig;
    }

    $dig = "sha1:" . io_sha1($self->raw_chunkref);

    $cache->set($key => $dig);

    return $self->{_raw_digest} = $dig;
}

sub raw_chunkref {
    my $self = shift;
    if ($self->{_raw_chunkref}) {
      $self->{_raw_chunkref}->seek(0, SEEK_SET);
      return $self->{_raw_chunkref};
    }

    my $fullpath = $self->{file}->fullpath;
    my $fh = IO::File->new($fullpath, 'r') or die "Failed to open $fullpath: $!";
    binmode($fh);

    my $ifh = IO::InnerFile->new($fh, $self->{offset}, $self->{length})
        or die "Failed to create inner file handle for $fullpath: $!\n";
    return $self->{_raw_chunkref} = $ifh;
}

# useful string for targets to key on.  of one of the forms:
#    "<digest>;to=<enc_to>"
#    "<digest>;raw"
#    "<digest>;gz"   (future)
sub inventory_key {
    my $self = shift;
    my $key = $self->raw_digest;
    if (my @rcpts = $self->root->gpg_rcpts) {
        $key .= ";to=@rcpts";
    } else {
        $key .= ";raw";
    }
    return $key;
}

sub forget_chunkref {
    my $self = shift;
    delete $self->{_raw_chunkref};
}

sub cachekey {
    my $self = shift;
    return $self->{file}->cachekey . ";o=$self->{offset};l=$self->{length}";
}

sub is_entire_file {
    my $self = shift;
    return $self->{file}->chunks == 1;
}

1;
