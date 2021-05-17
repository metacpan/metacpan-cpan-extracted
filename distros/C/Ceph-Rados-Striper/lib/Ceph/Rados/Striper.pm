package Ceph::Rados::Striper;

use 5.026001;
use strict;
use warnings;
use Carp;
use Ceph::Rados;
use Scalar::Util qw/blessed openhandle/;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our $VERSION = '0.09';

# Preloaded methods go here.

my $STRIPE_UNIT  = 64 * 1024;
my $STRIPE_COUNT = 5;
my $OBJECT_SIZE  = 120 * 1024 * 1024;
my $CHUNK_SIZE   = 1024 * 1024;

sub new {
    my ($class, $io_context) = @_;
    my $obj = create($io_context);
    bless $obj, $class;
    return $obj;
}

sub object_layout {
    my ($self, $stripe_unit, $stripe_count, $object_size) = @_;
    $stripe_unit  //= $STRIPE_UNIT;
    $stripe_count //= $STRIPE_COUNT;
    $object_size  //= $OBJECT_SIZE;
    $self->_object_layout($stripe_unit, $stripe_count, $object_size);
}

sub DESTROY {
    my $self = shift;
    $self->destroy if ${^GLOBAL_PHASE} eq 'DESTRUCT';
}

sub write {
    my ($self, $soid, $source) = @_;
    if (openhandle($source)) {
        &write_handle;
    } else {
        &write_data;
    }
}

sub write_handle_perl {
    my ($self, $soid, $handle) = @_;
    Carp::confess "Called with not an open handle"
        unless openhandle $handle;
    my $length = -s $handle
        or Carp::confess "Could not get size for filehandle $handle";
    $self->object_layout();
    my ($retval, $data);
    my $offset = 0;
    while (my $chunk_length = sysread($handle, $data, $CHUNK_SIZE)) {
        #printf "Writing bytes %i to %i\n", $offset, $offset+$length;
        $retval = $self->_write($soid, $data, $chunk_length, $offset)
            or last;
        $offset += $chunk_length;
    }
    return $retval;
}

sub write_handle {
    my ($self, $soid, $handle, $debug) = @_;
    Carp::confess "Called with not an open handle"
        unless openhandle $handle;
    my $length = -s $handle
        or Carp::confess "Could not get size for filehandle $handle";
    $self->object_layout();
    my $wrotelen = $self->_write_from_fh($soid, $handle, $length, $debug);
    if ($length != $wrotelen) {
        Carp::cluck "Expected to write $length bytes from handle, actually wrote $wrotelen bytes";
    }
    my $storedlen = $self->size($soid);
    if ($length != $storedlen) {
        Carp::cluck "Expected to write $length bytes from handle, stored object contains $storedlen bytes";
    }
    return $wrotelen;
}

sub write_data {
    my ($self, $soid, $data) = @_;
    my $length = length($data);
    $self->object_layout();
    my $retval;
    for (my $offset = 0; $offset <= $length; $offset += $CHUNK_SIZE) {
        my $chunk;
        if ($offset + $CHUNK_SIZE > $length) {
            $chunk = $length % $CHUNK_SIZE;
        } else {
            $chunk = $CHUNK_SIZE;
        }
        #printf "Writing bytes %i to %i\n", $offset, $offset+$chunk;
        $retval = $self->_write($soid, substr($data, $offset, $chunk), $chunk, $offset)
            or last;
    }
    return $retval;
}

sub append {
    my ($self, $soid, $data) = @_;
    $self->_append($soid, $data, length($data));
}

sub read_handle_perl {
    my ($self, $soid, $handle, $len, $off) = @_;
    my $is_filehandle = openhandle($handle);
    my $is_writable_object = blessed($handle) and $handle->can('write');
    Carp::confess "Called with neither an open filehandle equivalent nor an object with a \`write\` method"
        unless $is_filehandle or $is_writable_object;
    $off //= 0;
    if (!$len) {
        ($len, undef) = $self->_stat($soid);
    }
    my $count = 0;
    #
    for (my $pos = $off; $pos <= $len+$off; $pos += $CHUNK_SIZE) {
        my $chunk;
        if ($pos + $CHUNK_SIZE > $len) {
            $chunk = $len % $CHUNK_SIZE;
        } else {
            $chunk = $CHUNK_SIZE;
        }
        my $data = $self->_read($soid, $chunk, $pos);
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
    my ($self, $soid, $handle, $len, $off, $debug) = @_;
    if (blessed($handle) and $handle->can('write')) {
        &read_handle_perl;
    } elsif (openhandle $handle) {
        $self->_read_to_fh($soid, $handle, $len||0, $off||0);
    } else {
        Carp::confess "Called with neither an open filehandle equivalent nor an object with a \`write\` method";
    }
}

sub read {
    my ($self, $soid, $len, $off) = @_;
    # if undefined is passed as len, we stat the obj first to get the correct len
    if (!defined($len)) {
        ($len, undef) = $self->stat($soid);
    }
    $off ||= 0;
    $self->_read($soid, $len, $off);
}

sub stat {
    my ($self, $soid) = @_;
    $self->_stat($soid);
}

sub mtime {
    my ($self, $soid) = @_;
    my (undef, $mtime) = $self->stat($soid);
    $mtime;
}

sub size {
    my ($self, $soid) = @_;
    my ($size, undef) = $self->stat($soid);
    $size;
}

sub remove  {
    my ($self, $soid) = @_;
    $self->object_layout();
    $self->_remove($soid);
}

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Ceph::Rados::Striper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	LIBRADOSSTRIPER_VERSION_CODE
	LIBRADOSSTRIPER_VER_EXTRA
	LIBRADOSSTRIPER_VER_MAJOR
	LIBRADOSSTRIPER_VER_MINOR
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	LIBRADOSSTRIPER_VERSION_CODE
	LIBRADOSSTRIPER_VER_EXTRA
	LIBRADOSSTRIPER_VER_MAJOR
	LIBRADOSSTRIPER_VER_MINOR
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Ceph::Rados::Striper::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Ceph::Rados::Striper', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ceph::Rados::Striper - Perl extension to wrap libradosstriper-dev and provide striping for L<Ceph::Rados>.

=head1 SYNOPSIS

  use Ceph::Rados;
  use Ceph::Rados::Striper;

  Ceph::Rados::Striper->new($ioctx);

=head1 DESCRIPTION

A mostly drop-in replacement for L<Ceph::Radio::IO> objects, which provides read/write/delete/stat methods

=head2 EXPORT

None by default.

=head2 Exportable constants

  LIBRADOSSTRIPER_VERSION_CODE
  LIBRADOSSTRIPER_VER_EXTRA
  LIBRADOSSTRIPER_VER_MAJOR
  LIBRADOSSTRIPER_VER_MINOR

=head1 METHODS

=head2 object(stripe_unit, stripe_count, object_size)

Sets the object layout.  Defaults are 64k, 5, and 120Mb.

Stripe unit is the smallest unit of data.  Files will be zero padded up to a multiple of this.

Stripe count is the number of stripes per object.

Object size is the threshold at which an extra set of stripes will be created.  i.e. for the defaults, a 121Mb file will have 10 stripes.

=head2 write(soid, source)

Wraps C<rados_write()>.  Write data from the source, to a ceph object with the supplied ID.  Source can either be a perl scalar, or a handle to read data from.  Returns 1 on success.  Croaks on failure.

=head2 write_data(soid, data)

=head2 write_handle(soid, handle)

As L<write_data()>, but explicitly declaring the source type.

=head2 append(soid, data)

Wraps C<rados_striper_append()>.  Appends data to the ceph object with the supplied ID.  Data must be a perl scalar, not a handle.  Returns 1 on success.  Croaks on failure.

=head2 stat(soid)

Wraps C<rados_striper_stat()>.  Returns a 2-element list of (filesize, mtime) for the ceph object with the supplied ID.

=head2 read(soid, len=filesize, offset=0)

Wraps C<rados_striper_read()>.  Read data from the ceph object with the supplied ID, and return the data read.  Croaks on failure.

=head2 read_handle(soid, handle)

As C<read()>, but writes the data directly to the supplied handle instead of returning it.

=head2 remove(soid)

Wraps C<rados_striper_remove()>.  Deletes the ceph object with the supplied ID.  Returns 1 on success.  Croaks on failure.


=head1 SEE ALSO

libradosstriper-dev
L<Ceph::Rados>

=head1 AUTHOR

Alex Bowley, E<lt>alex@openimp.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Alex Bowley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
