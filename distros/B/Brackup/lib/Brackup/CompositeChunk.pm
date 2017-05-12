package Brackup::CompositeChunk;

use strict;
use warnings;
use Carp qw(croak);
use Fcntl qw(SEEK_SET);
use Brackup::Util qw(tempfile_obj io_sha1 io_print_to_fh); 

use fields (
            'used_up',
            'max_size',
            'target',
            'digest',  # memoized
            'finalized', # if we've written ourselves to the target yet
            'subchunks', # the chunks this composite chunk is made of
            'sha1',         # Digest::SHA1 object
            '_chunk_fh',  # tempfile file containing the whole composite chunk
            );

sub new {
    my ($class, $root, $target) = @_;
    my $self = ref $class ? $class : fields::new($class);
    $self->{used_up}   = 0; # bytes
    $self->{finalized} = 0; # false
    $self->{max_size}  = $root->max_composite_size;
    $self->{target}    = $target;
    $self->{subchunks} = [];
    $self->{sha1}      = Digest::SHA1->new;
    $self->{_chunk_fh} = tempfile_obj();
    return $self;
}

sub append_little_chunk {
    my ($self, $schunk) = @_;
    die "ASSERT" if $self->{digest}; # its digest was already requested?

    my $from = $self->{used_up};
    $self->{used_up} += $schunk->backup_length;
    io_print_to_fh($schunk->chunkref, $self->{_chunk_fh}, $self->{sha1});
    my $to = $self->{used_up};

    $schunk->set_composite_chunk($self, $from, $to);
    push @{$self->{subchunks}}, $schunk;
}

sub digest {
    my $self = shift;
    return $self->{digest} ||= "sha1:" . $self->{sha1}->hexdigest;
}

sub can_fit {
    my ($self, $len) = @_;
    return $len <= ($self->{max_size} - $self->{used_up});
}

# return on success; die on any failure
sub finalize {
    my $self = shift;
    die "ASSERT" if $self->{finalized}++;

    $self->{target}->store_chunk($self)
        or die "chunk storage of composite chunk failed.\n";

    foreach my $schunk (@{$self->{subchunks}}) {
        $self->{target}->add_to_inventory($schunk->pchunk => $schunk);
    }

    $self->forget_chunkref;

    return 1;
}

sub stored_chunk_from_dup_internal_raw {
    my ($self, $pchunk) = @_;
    my $ikey = $pchunk->inventory_key;
    foreach my $schunk (@{$self->{subchunks}}) {
        next unless $schunk->pchunk->inventory_key eq $ikey;
        # match!  found a duplicate within ourselves
        return $schunk->clone_but_for_pchunk($pchunk);
    }
    return undef;
}

# <duck-typing>
# make this duck-typed like a StoredChunk, so targets can store it
*backup_digest = \&digest;
sub backup_length {
    my $self = shift;
    return $self->{used_up};
}
# return handle to data
sub chunkref {
    my $self = shift;
    croak "ASSERT: _chunk_fh not opened" unless $self->{_chunk_fh}->opened;
    seek($self->{_chunk_fh}, 0, SEEK_SET);
    return $self->{_chunk_fh};
}
sub inventory_value {
    die "ASSERT: don't expect this to be called";
}
# called when chunk data not needed anymore
sub forget_chunkref {
    my $self = shift;
    if ($self->{_chunk_fh}) {
        die "ASSERT: used_up: $self->{used_up}, size: " . -s $self->{_chunk_fh}->filename
            unless -s $self->{_chunk_fh}->filename == $self->{used_up};
        close $self->{_chunk_fh};
        delete $self->{_chunk_fh};      # also deletes the temp file
    }
}
# </duck-typing>

1;
