package Ceph::Rados::IO;

use 5.014002;
use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;

use Ceph::Rados::List;

our @ISA = qw();

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
    $self->destroy;
}

sub write {
    my ($self, $oid, $source) = @_;
    my $tell;
    {
        local $^W = 0;
        $tell = tell($source)
    }
    if ($tell) {
        &write_handle;
    } else {
        &write_data;
    }
}

sub write_handle {
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

sub write_data {
    my ($self, $oid, $data) = @_;
    my $length = length($data);
    my $retval;
    for (my $offset = 0; $offset <= $length; $offset += $DEFAULT_OSD_MAX_WRITE) {
        my $chunk;
        if ($offset + $DEFAULT_OSD_MAX_WRITE > $length) {
            $chunk = $length % $DEFAULT_OSD_MAX_WRITE;
        } else {
            $chunk = $DEFAULT_OSD_MAX_WRITE;
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

sub read_handle {
    my ($self, $oid, $handle) = @_;
    (my $length, undef) = $self->_stat($oid);
    #
    for (my $offset = 0; $offset <= $length; $offset += $DEFAULT_OSD_MAX_WRITE) {
        my $chunk;
        if ($offset + $DEFAULT_OSD_MAX_WRITE > $length) {
            $chunk = $length % $DEFAULT_OSD_MAX_WRITE;
        } else {
            $chunk = $DEFAULT_OSD_MAX_WRITE;
        }
        my $data = $self->_read($oid, $chunk, $offset);
        syswrite $handle, $data;
    }
}

sub read {
    my ($self, $oid, $len, $off) = @_;
    # if undefined is passed as len, we stat the obj first to get the correct len
    if (!defined($len)) {
        ($len, undef) = $self->_stat($oid);
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
    my (undef, $mtime) = $self->_stat($oid);
    $mtime;
}

sub size {
    my ($self, $oid) = @_;
    my ($size, undef) = $self->_stat($oid);
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
