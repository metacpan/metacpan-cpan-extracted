package Ceph::Rados::IO;

use 5.014002;
use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed openhandle/;

use Ceph::Rados::List;

our @ISA = qw();

my $CHUNK_SIZE = 1024 * 1024;

# Preloaded methods go here.

# TODO should query cluster for this value
my $DEFAULT_OSD_MAX_WRITE = 90 * 1024 * 1024;

sub new {
    my ($class, $context, $pool_name) = @_;
    my $obj = create($context, $pool_name);
    bless $obj, $class;
    return $obj;
}

sub list {
    my $self = shift;
    Ceph::Rados::List->new($self);
}

sub DESTROY {
    my $self = shift;
    $self->destroy if ${^GLOBAL_PHASE} eq 'DESTRUCT';
}

sub write {
    my ($self, $oid, $source) = @_;
    if (openhandle($source)) {
        &write_handle;
    } else {
        &write_data;
    }
}

sub write_handle_perl {
    my ($self, $oid, $handle) = @_;
    my ($retval, $data);
    my $offset = 0;
    while (my $length = sysread($handle, $data, $DEFAULT_OSD_MAX_WRITE)) {
        #printf "Writing bytes %i to %i\n", $offset, $offset+$length;
        $retval = $self->_write($oid, $data, $length, $offset)
            or last;
        # add returned length to offset, not read length - they shouldn't differ, but this is probably safer
        $offset += $length;
    }
    return $retval;
}

sub write_handle {
    my ($self, $oid, $handle) = @_;
    Carp::confess "Called with not an open handle"
        unless openhandle $handle;
    my $length = -s $handle
        or Carp::confess "Could not get size for filehandle $handle";
    $self->_write_from_fh($oid, $handle, $length);
}

sub write_data {
    my ($self, $oid, $data) = @_;
    my $length = length($data);
    my $retval;
    for (my $offset = 0; $offset <= $length; $offset += $CHUNK_SIZE) {
        my $chunk;
        if ($offset + $CHUNK_SIZE > $length) {
            $chunk = $length % $CHUNK_SIZE;
        } else {
            $chunk = $CHUNK_SIZE;
        }
        #printf "Writing bytes %i to %i\n", $offset, $offset+$chunk;
        $retval = $self->_write($oid, substr($data, $offset, $chunk), $chunk, $offset)
            or last;
    }
    return $retval;
}

sub append {
    my ($self, $oid, $data) = @_;
    $self->_append($oid, $data, length($data));
}

sub read_handle_perl {
    my ($self, $oid, $handle, $len, $off) = @_;
    my $is_filehandle = openhandle($handle);
    my $is_writable_object = blessed($handle) and $handle->can('write');
    Carp::confess "Called with neither an open filehandle equivalent nor an object with a \`write\` method"
        unless $is_filehandle or $is_writable_object;
    $off //= 0;
    if (!$len) {
        ($len, undef) = $self->_stat($oid);
    }
    my $count = 0;
    #
    for (my $pos = 0; $pos <= $len; $pos += $DEFAULT_OSD_MAX_WRITE) {
        my $chunk;
        if ($pos + $DEFAULT_OSD_MAX_WRITE > $len) {
            $chunk = $len % $DEFAULT_OSD_MAX_WRITE;
        } else {
            $chunk = $DEFAULT_OSD_MAX_WRITE;
        }
        my $data = $self->_read($oid, $chunk, $pos);
        if ($is_filehandle) {
            syswrite $handle, $data;
        } else {
            $handle->write($data)
        }
        $count += length $data;
    }
    return $count;
}

sub read_handle {
    my ($self, $oid, $handle, $len, $off) = @_;
    if (blessed($handle) and $handle->can('write')) {
        &read_handle_perl;
    } elsif (openhandle $handle) {
        $self->_read_to_fh($oid, $handle, $len||0, $off||0);
    } else {
        Carp::confess "Called with neither an open filehandle equivalent nor an object with a \`write\` method";
    }
}


sub read {
    my ($self, $oid, $len, $off) = @_;
    # if undefined is passed as len, we stat the obj first to get the correct len
    if (!defined($len)) {
        ($len, undef) = $self->stat($oid);
    }
    $off ||= 0;
    $self->_read($oid, $len, $off);
}

sub stat {
    my ($self, $oid) = @_;
    $self->_stat($oid);
}

sub pool_required_alignment {
    my ($self) = @_;
    return $self->_pool_required_alignment();
}

sub mtime {
    my ($self, $oid) = @_;
    my (undef, $mtime) = $self->stat($oid);
    $mtime;
}

sub size {
    my ($self, $oid) = @_;
    my ($size, undef) = $self->stat($oid);
    $size;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ceph::Rados::IO - Perl wrapper to librados IO context.

=head1 METHODS

=head2 list()

Wraps C<rados_objects_list_open()>.  Returns a list context for the pool, as a L<Ceph::Rados::List> object.

=head2 write(oid, source)

Wraps C<rados_write()>.  Write data from the source, to a ceph object with the supplied ID.  Source can either be a perl scalar, or a handle to read data from.  Returns 1 on success.  Croaks on failure.

=head2 write_data(oid, data)

=head2 write_handle(oid, handle)

As L<write_data()>, but explicitly declaring the source type.

=head2 append(oid, data)

Wraps C<rados_append()>.  Appends data to the ceph object with the supplied ID.  Data must be a perl scalar, not a handle.  Returns 1 on success.  Croaks on failure.

=head2 stat(oid)

Wraps C<rados_stat()>.  Returns a 2-element list of (filesize, mtime) for the ceph object with the supplied ID.

=head2 read(oid, len=filesize, offset=0)

Wraps C<rados_read()>.  Read data from the ceph object with the supplied ID, and return the data read.  Croaks on failure.

=head2 read_handle(oid, handle)

As C<read()>, but writes the data directly to the supplied handle instead of returning it.

=head2 remove(oid)

Wraps C<rados_remove()>.  Deletes the ceph object with the supplied ID.  Returns 1 on success.  Croaks on failure.

=cut
