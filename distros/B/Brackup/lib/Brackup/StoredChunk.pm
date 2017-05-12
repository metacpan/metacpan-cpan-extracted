package Brackup::StoredChunk;

use strict;
use warnings;
use Carp qw(croak);
use Brackup::Util qw(io_sha1);
use Fcntl qw(SEEK_SET);

# fields:
#   pchunk - always
#   backlength - memoized
#   backdigest - memoized
#   _chunkref  - memoized
#   compchunk  - composite chunk, if we were added to a composite chunk
#   compfrom   - offset in composite chunk where we start
#   compto     - offset in composite chunk where we end
#   lite       - true if this is a 'lite' or 'handle' version

sub new {
    my ($class, $pchunk) = @_;
    my $self = bless {}, $class;
    $self->{pchunk} = $pchunk;
    return $self;
}

sub pchunk { $_[0]{pchunk} }

# create the 'lite' or 'handle' version of a storedchunk.  can't get to
# the chunkref from this, but callers aren't won't.  and we'll DIE if they
# try to access the chunkref.
sub new_from_inventory_value {
    my ($class, $pchunk, $invval) = @_;

    my ($dig, $len, $range) = split /\s+/, $invval;

    my $sc = bless {
        pchunk     => $pchunk,
        backdigest => $dig,
        backlength => $len,
        lite       => 1,
    }, $class;

    # normal
    return $sc unless $range;

    # in case of little file in a composite chunk,
    # we gotta be a range.
    my ($from, $to) = $range =~ /^(\d+)-(\d+)$/
        or die "bogus range: $range";
    $sc->{compfrom} = $from;
    $sc->{compto}   = $to;
    return $sc;
}

sub clone_but_for_pchunk {
    my ($self, $pchunk) = @_;
    my $copy = bless {}, ref $self;
    foreach my $f (qw(backlength backdigest compchunk compfrom compto)) {
        $copy->{$f} = $self->{$f};
    }
    $copy->{pchunk} = $pchunk;
    return $copy;
}

sub set_composite_chunk {
    my ($self, $cchunk, $from, $to) = @_;
    $self->{compchunk} = $cchunk;

    # forget our backup length/digest.  this handle information
    # to the stored chunk should be asked of our composite
    # chunk in the future, when it's done populating.
    $self->{backdigest} = undef;
    $self->{backlength} = undef;
    $self->forget_chunkref;

    $self->{compfrom}  = $from;
    $self->{compto}    = $to;
}

sub range_in_composite {
    my $self = shift;
    return undef unless $self->{compfrom} || $self->{compto};
    return "$self->{compfrom}-$self->{compto}";
}

sub file {
    my $self = shift;
    return $self->{pchunk}->file;
}

sub root {
    my $self = shift;
    return $self->file->root;
}

# returns true if encrypted, false otherwise
sub encrypted {
    my $self = shift;
    return $self->root->gpg_rcpts ? 1 : 0;
}

sub compressed {
    my $self = shift;
    # TODO/FUTURE: support compressed chunks (for non-encrypted
    # content; gpg already compresses)
    return 0;
}

# the original length, pre-encryption
sub length {
    my $self = shift;
    return $self->{pchunk}->length;
}

# the length, either encrypted or not
sub backup_length {
    my $self = shift;
    return $self->{backlength} if defined $self->{backlength};
    $self->_populate_lengthdigest;
    return $self->{backlength};
}

# the digest, either encrypted or not
sub backup_digest {
    my $self = shift;
    return $self->{backdigest} if $self->{backdigest};
    $self->_populate_lengthdigest;
    return $self->{backdigest};
}

sub _populate_lengthdigest {
    my $self = shift;

    # Composite chunk version
    if (my $cchunk = $self->{compchunk}) {
        $self->{backlength} = $cchunk->backup_length;
        $self->{backdigest} = $cchunk->digest;
        return 1;
    }

    die "ASSERT: encrypted length or digest not set" if $self->encrypted;

    # Unencrypted version
    $self->{backdigest} = "sha1:" . io_sha1($self->{pchunk}->raw_chunkref);
    $self->{backlength} = $self->{pchunk}->length;  # length of raw data
    return 1;
}

sub chunkref {
    my $self = shift;
    if ($self->{_chunkref}) {
      $self->{_chunkref}->seek(0, SEEK_SET);
      return $self->{_chunkref};
    }

    # encrypting case: chunkref gets set via set_encrypted_chunkref in Backup::backup
    croak "ASSERT: encrypted but no chunkref set" if $self->encrypted;

    # caller/consistency check:
    Carp::confess("Can't access chunkref on lite StoredChunk instance (handle only)")
        if $self->{lite};

    # non-encrypting case
    return $self->{_chunkref} = $self->{pchunk}->raw_chunkref;
}

# set encrypted chunk filehandle and digest/length
sub set_encrypted_chunkref {
    my ($self, $fh, $enc_length) = @_;
    die "ASSERT: not enc"      unless $self->encrypted;
    die "ASSERT: already set?" if $self->{backlength} || $self->{backdigest};

    $self->{backdigest} = "sha1:" . io_sha1($fh);
    $self->{backlength} = $enc_length;

    return $self->{_chunkref} = $fh;
}

# lose the chunkref data
sub forget_chunkref {
    my $self = shift;
    return unless $self->{_chunkref};
    $self->{_chunkref}->close;
    delete $self->{_chunkref};      # this also deletes the tempfile, if any
}

# to the format used by the metafile
sub to_meta {
    my $self = shift;
    my @parts = ($self->{pchunk}->offset,
                 $self->{pchunk}->length);

    if (my $range = $self->range_in_composite) {
        push @parts, (
                      $range,
                      $self->backup_digest,
                      );
    } else {
        push @parts, (
                      $self->backup_length,
                      $self->backup_digest,
                      );
    }

    # if the inventory database is lost, it should be possible to
    # recover the inventory database from the *.brackup files.
    # if a file only has on chunk, the digest(raw) -> digest(enc)
    # can be inferred from the file's digest, then the stored
    # chunk's digest.  but if we have multiple chunks, we need
    # to store each chunk's raw digest as well in the chunk
    # list.  we could do this all the time, but considering
    # most files are small, we want to save space in the *.brackup
    # meta file and only do it when necessary.
    if ($self->encrypted && $self->file->chunks > 1) {
        push @parts, $self->{pchunk}->raw_digest;
    }

    return join(";", @parts);
}

# aka "instructions to attach to a pchunk, on how to recover the pchunk from a target"
sub inventory_value {
    my $self = shift;

    # when this chunk was stored as part of a composite chunk, the instructions
    # are of form:
    #    sha1:deadbeef 0-50
    # which means download "sha1:deadbeef", then the contents will be in from
    # byte offset 0 to byte offset 50 (length of 50).
    if (my $range = $self->range_in_composite) {
        return join(" ",
                    $self->backup_digest,
                    $self->backup_length,
                    $range);
    }

    # else, the historical format:
    #   sha1:deadbeef <length>
    return join(" ", $self->backup_digest, $self->backup_length);
}

1;
