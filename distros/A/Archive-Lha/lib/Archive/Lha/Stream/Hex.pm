package Archive::Lha::Stream::Hex;

use strict;
use warnings;
use Carp;
use base qw( Archive::Lha::Stream::Base );

sub open {
  my ($self, %options) = @_;

  croak "Array reference of hex strings is missing" unless ref $options{hex} eq 'ARRAY';

  my @array = map { pack 'H2', $_ } @{ $options{hex} };

  $self->{array}  = \@array;
  $self->{length} = scalar @array;
  $self->{pos}    = 0;
}

sub read {
  my ($self, $length) = @_;

  my $from = $self->{pos};
  my $to   = $self->{pos} + $length - 1;
     $to   = $self->{length} - 1 if $to >= $self->{length};
  my $str = join '', @{ $self->{array} }[$from .. $to];
  $self->{pos} = $to + 1;
  return $str;
}

1;

__END__

=head1 NAME

Archive::Lha::Stream::Hex

=head1 SYNOPSIS

  my $stream = Archive::Lha::Stream::Hex->new( hex => [qw( 4D 00 2D ...)] );

=head1 DESCRIPTION

This is for debugging. You usually don't need to use this.

=head1 METHODS

=head2 new

creates an object, and optionally stores an array of hex strings in the object.

=head2 open

takes a hash as an argument and stores the array of hex strings in the object.

=head2 close

does nothing.

=head2 eof

sees if the position reached end of array.

=head2 tell

returns the current position.

=head2 seek

takes an offset as an argument and sets the position from the array top.

=head2 read

takes a length as an argument and returns the chunks of the length (in bytes) from the array.

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
