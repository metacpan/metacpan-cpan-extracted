package Articulate::File;
use strict;
use warnings;
use Moo;
use overload '""' => sub { shift->_to_string };

=head1 NAME

Articulate::File - represent a file

=cut

=head1 DESCRIPTION

This represents a binary blob of content which is uploaded as a file
and should ideally be moved straight into the database rather than
loaded into memory.

It may also in future be used to represent files on the way out. The
interface is currently unstable as it is largely copied from Dancer's
file handling and is written to 'what works'.

=head1 ATTRIBUTES

=cut

=head3 content_type

The MIME type of the content.

=cut

has content_type => ( is => 'rw', );

=head3 headers

The HTTP headers which came with the file.

=cut

has headers => ( is => 'rw', );

=head3 filename

The name of the file.

=cut

has filename => ( is => 'rw', );

=head3 io

The IO::All object which corresponds to the file handle.

=cut

has io => ( is => 'rw', );

sub _to_string {
  my $self = shift;
  local $/;
  join '', $self->io->getlines;
}

1;
