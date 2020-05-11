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

sub write_handle {
    my ($self, $soid, $handle) = @_;
    my $length = -s $handle
        or die "Could not get size for filehandle $handle";
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

sub write_data {
    my ($self, $oid, $data) = @_;
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
    for (my $offset = 0; $offset <= $length; $offset += $CHUNK_SIZE) {
        my $chunk;
        if ($offset + $CHUNK_SIZE > $length) {
            $chunk = $length % $CHUNK_SIZE;
        } else {
            $chunk = $CHUNK_SIZE;
        }
        my $data = $self->_read($oid, $chunk, $offset);
        syswrite $handle, $data;
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

our $VERSION = '0.01';

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

Stub documentation for Ceph::Rados::Striper, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

=head2 EXPORT

None by default.

=head2 Exportable constants

  LIBRADOSSTRIPER_VERSION_CODE
  LIBRADOSSTRIPER_VER_EXTRA
  LIBRADOSSTRIPER_VER_MAJOR
  LIBRADOSSTRIPER_VER_MINOR



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
