package Archive::Lha::Stream::String;

use strict;
use warnings;
use Carp;
use bytes;
use base qw( Archive::Lha::Stream::Base );

sub open {
  my ($self, %options) = @_;

  $self->{string} = $options{string} or croak "String is missing";
  $self->{length} = length( $options{string} );
  $self->{pos} = 0;
}

sub close { return }

sub read {
  my ($self, $length) = @_;

  my $str = substr( $self->{string}, $self->{pos}, $length );
  $self->{pos} += $length;
  return $str;
}

1;

__END__

=head1 NAME

Archive::Lha::Stream::String

=head1 SYNOPSIS

  my $stream = Archive::Lha::Stream::String->new( string => 'content_of_lzh_file' );

=head1 DESCRIPTION

Sometimes you might want to read the content of an .lzh file from DB and the likes. You don't need to prepare a temporary file to store it. Just pass it directly to this stream.

=head1 METHODS

=head2 new

creates an object, and optionally store a string in the object.

=head2 open

takes a hash as an argument and stores the string in the object.

=head2 close

does nothing.

=head2 eof

sees if the position reached end of the string.

=head2 tell

returns the current position.

=head2 seek

takes an offset as an argument and sets the position from the string top.

=head2 read

takes a length as an argument and returns the chunks of the length (in bytes) from the string.

=head2 search_header

searches for the next lzh header.

=head1 SEE ALSO

L<Archive::Lha::Stream>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
