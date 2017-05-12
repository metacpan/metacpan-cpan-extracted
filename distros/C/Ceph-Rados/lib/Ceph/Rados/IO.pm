package Ceph::Rados::IO;

use 5.014002;
use strict;
use warnings;
use Carp;

use Ceph::Rados::List;

our @ISA = qw();

our $VERSION = '0.01';

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
    my ($self, $oid, $data) = @_;
    my $length = length($data);
    my $retval;
    for (my $offset = 0; $offset < $length; $offset += $DEFAULT_OSD_MAX_WRITE) {
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

Ceph::Rados - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Ceph::Rados;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Ceph::Rados, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Alex, E<lt>alex@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Alex

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
