# $Id: PlainFile.pm,v 1.2 2002/04/23 04:19:05 barbee Exp $

=head1 NAME

Apache::CVS::PlainFile - class that implements a file in CVS

=head1 SYNOPSIS

 use Apache::CVS::PlainFile();

 $file = Apache::CVS::PlainFile->new($path);

 $path = $file->path();
 $name = $file->name();

=head1 DESCRIPTION

The C<Apache::CVS::PlainFile> class implements a base file that resides in a CVS
repository. A versioned file is implemented by the class
C<Apache::CVS::VersionPlainFile>.

=over 4

=cut

package Apache::CVS::PlainFile;

use strict;

$Apache::CVS::PlainFile::VERSION = $Apache::CVS::VERSION;

=item $file = Apache::CVS::PlainFile->new($path)

Construct a new C<Apache::CVS::PlainFile> object with the given path.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    $self->{path} = shift;

    bless ($self, $class);
    return $self;
}

=item $file->path()

Returns the full path of this file.

=cut

sub path {
    my $self = shift;
    $self->{path} = shift if scalar @_;
    return $self->{path};
}

=item $file->name()

Returns just the filename of this file.

=cut 

sub name {
    my $self = shift;
    $self->{path} =~ m#\/([^\/]*)$#;
    return $1;
}

=back

=head1 SEE ALSO

L<Apache::CVS>, L<Apache::CVS::File>, L<Apache::CVS::Directory>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
