package Archive::Lha::Decode::LH0;

use strict;
use warnings;
use Carp;
use bytes;
use Archive::Lha::Constants;
use Archive::Lha::CRC;

sub new {
  my ($class, %options) = @_;

  my $header = $options{header};

  my $self  = bless {
    read  => $options{read},
    write => $options{write},
    size  => $header->{encoded_size},
    crc16 => $header->{crc16},
  }, $class;

  $self;
}

sub decode {
  my $self = shift;

  my $crc   = 0;
  my $total = 0;
  my $size  = $self->{size};
  while ( $total < $size ) {
    my $left = $size - $total;
    my $length = ( $left > 4096 ) ? 4096 : $left;
    my $str = $self->{read}->( $length );
    $self->{write}->( $str );
    $crc = Archive::Lha::CRC::update( $crc, $str, length($str) );
    $total += $length;
  }
  return $crc;
}

1;

__END__

=head1 NAME

Archive::Lha::Decode::LH0

=head1 DESCRIPTION

This is a lh0 decoder -- actually, as lh0 archive is not decoded, this just reads the lh0 body and writes it out.

=head1 METHODS

=head2 new

creates an object.

=head2 decode

reads the lh0 body and writes it out.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
