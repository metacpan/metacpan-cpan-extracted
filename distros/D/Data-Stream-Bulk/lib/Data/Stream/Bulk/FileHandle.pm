package Data::Stream::Bulk::FileHandle;
BEGIN {
  $Data::Stream::Bulk::FileHandle::AUTHORITY = 'cpan:NUFFIN';
}
{
  $Data::Stream::Bulk::FileHandle::VERSION = '0.11';
}
use Moose;
# ABSTRACT: read lines from a filehandle

use namespace::clean -except => 'meta';

use IO::Handle;

with 'Data::Stream::Bulk::DoneFlag';

has filehandle => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 1,
);

sub get_more {
    my $self = shift;

    my $line = $self->filehandle->getline;
    return unless defined $line;
    return [ $line ];
}

__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=head1 NAME

Data::Stream::Bulk::FileHandle - read lines from a filehandle

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use Data::Stream::Bulk::FileHandle;
  use Path::Class;

  my $s = Data::Stream::Bulk::FileHandle->new(
      filehandle => file('foo.txt')->openr,
  );

=head1 DESCRIPTION

This provides a stream API for reading lines from a file.

=head1 ATTRIBUTES

=over 4

=item filehandle

A file handle that has been opened for reading. The stream will return lines
from this file, one by one.

=back

=head1 METHODS

=over 4

=item get_more

See L<Data::Stream::Bulk::DoneFlag>.

Returns the next line from the file, if it exists.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

