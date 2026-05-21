package Archive::Lha::Stream::Base;

use strict;
use warnings;
use Carp;

sub new {
  my $class = shift;
  my $self  = bless {}, $class;
  $self->open(@_);
  $self;
}

sub open { croak "override" }

sub close { return }

sub search_header {
  my $self = shift;

  my $str   = '';
  my $count = 0;
  my $pos   = $self->tell;
  until ( $self->eof ) {
    $str .= $self->read(1024);
    my ($method, $level) = $str =~ /.{2}\-(lh[0-9a-z]|lzs|lz[45]|pm[012])\-.{13}(.)/s;
    if ( defined $level ) {
      $level = ord( $level );
      if ( $method && $level =~ /^(?:[0-2])$/) {
        $self->seek( $pos );
        return $level;
      }
    }
    $str = substr( $str, -21 );
    last if ++$count > 63;  # further check would be fruitless
  }
  return;
}

sub eof {
  my $self = shift;

  $self->{pos} >= $self->{length};
}

sub seek {
  my ($self, $offset) = @_;
  $self->{pos} = $offset;
}

sub tell { shift->{pos} }

sub read { croak "override" }

1;

__END__

=head1 NAME

Archive::Lha::Stream::Base

=head1 DESCRIPTION

This is a base class for ::Stream subclasses.

=head1 METHODS

=head2 new

creates an object, and optionally opens the target.

=head2 open

takes a hash as an argument and does appropriate things for the subclass.

=head2 close

does appropriate things for the subclass.

=head2 eof

sees if the position reached end of the file/string/array.

=head2 tell

returns the current position.

=head2 seek

takes an offset as an argument and sets the position from the top.

=head2 read

takes a length as an argument and returns the chunks of the length (in bytes).

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
