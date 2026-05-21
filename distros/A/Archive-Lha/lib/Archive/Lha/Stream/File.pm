package Archive::Lha::Stream::File;

use strict;
use warnings;
use Carp;
use Fcntl qw( :flock :seek );
use base qw( Archive::Lha::Stream::Base );

sub open {
  my ($self, %options) = @_;

  open my $fh, '<:raw', $options{file}
    or croak "Can't open $options{file}: $!";
  flock $fh, LOCK_SH
    or croak "Can't lock $options{file}: $!";
  binmode $fh;

  $self->{fh} = $fh;
}

sub close {
  my $self = shift;

  close $self->{fh};

  delete $self->{fh};
}

sub eof {
  my $self = shift;

  eof $self->{fh};
}

sub seek {
  my ($self, $offset) = @_;

  seek $self->{fh}, $offset, SEEK_SET;
}

sub tell {
  my ($self, $offset) = @_;

  tell $self->{fh};
}

sub read {
  my ($self, $length) = @_;

  read $self->{fh}, ( my $chunk ), $length;

  return $chunk;
}

1;

__END__

=head1 NAME

Archive::Lha::Stream::File

=head1 SYNOPSIS

  my $stream = Archive::Lha::Stream::File->new;
  $stream->open( file => 'some.lzh' );

  # equivalent
  my $stream = Archive::Lha::Stream::File->new( file => 'some.lzh' );

=head1 DESCRIPTION

This is a thin wrapper for the builtin I/O functions.

=head1 METHODS

=head2 new

creates an object, and optionally opens an archive file.

=head2 open

takes a hash as an argument and opens a specified file, locks it, and makes it raw, binary mode.

=head2 close

closes the file.

=head2 eof

sees if the file reached end of file.

=head2 tell

returns the current position.

=head2 seek

takes an offset as an argument and sets the position from the file top.

=head2 read

takes a length as an argument and returns the chunks of the length (in bytes) from the file.

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
