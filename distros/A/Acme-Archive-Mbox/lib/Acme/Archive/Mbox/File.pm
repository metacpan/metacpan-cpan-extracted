package Acme::Archive::Mbox::File;

use warnings;
use strict;

=head1 NAME

Acme::Archive::Mbox::File - Archive::Mbox file

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

No user-servicable parts inside.

    use Acme::Archive::Mbox::File;

    my $file = Acme::Archive::Mbox->new(name => 'file/name', contents => $contents, ...);

=head1 FUNCTIONS

=head2 new

Create an Acme::Archive::Mbox::File object.

=cut

sub new {
    my $class = shift;
    my $name = shift;
    my $contents = shift;
    my %attr = @_;

    my $self = { name => $name, contents => $contents, %attr };
    return unless ($self->{name} and $self->{contents});
    return bless $self, $class;
}

=head2 name

Returns the name of the file.

=cut

sub name {
    my $self = shift;
    return $self->{name};
}

=head2 contents

Returns the contents of the file.

=cut

sub contents {
    my $self = shift;
    return $self->{contents};
}

=head2 mode

Returns the mode of the file.

=cut

sub mode {
    my $self = shift;
    return $self->{mode};
}

=head2 uid

Returns the owner's uid.

=cut

sub uid {
    my $self = shift;
    return $self->{uid};
}

=head2 gid

Returns the gid of the group which owns the file.

=cut

sub gid {
    my $self = shift;
    return $self->{gid};
}

=head2 mtime

Returns the mtime of the file as a unix timestamp.

=cut

sub mtime {
    my $self = shift;
    return $self->{mtime};
}

=head1 AUTHOR

Ian Kilgore, C<< <iank at cpan.org> >>

=head1 BUGS

=over 4

=item This module is pretty much a hash.  Don't expect it to be very robust.

=back

=head1 NOTES

=over 4

=item No special precaution is made against storing files with absolute
paths or directory traversals in their names; this is up to the
extraction tool.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ian Kilgore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::Archive::Mbox
