package Archive::Lha::Constants;

use strict;
use warnings;

sub import {
  my $class  = shift;
  my $caller = caller;

  my %size = ( CHAR => 1, UCHAR => 1, USHORT => 2 );
  my %const;
  foreach my $type ( keys %size ) {
    $const{$type.'_SIZE'} = $size{$type};
    $const{$type.'_BIT'}  = $size{$type} * 8;
    $const{$type.'_MAX'}  = ( 1 << $size{$type} * 8 ) - 1;
  }
  $const{USHORT_CENTER} = int( ( $const{USHORT_MAX} + 1 ) / 2 );

  {
    no strict 'refs';
    foreach my $key ( keys %const ) {
      *{"$caller\::$key"} = sub () { $const{$key} };
    }
    *{"$caller\::_ushort"} = sub { shift() & $const{USHORT_MAX} };
    *{"$caller\::_uchar"}  = sub { shift() & $const{UCHAR_MAX} };
    *{"$caller\::_bit_length"} = \&_bit_length;
  }
}

sub _bit_length {
  my $bits   = shift;
  my $length = 0;
  while ( $bits ) { $bits >>= 1; $length++; }
  return $length;
}

1;

__END__

=head1 NAME

Archive::Lha::Constants

=head1 DESCRIPTION

This is used internally to export several utility functions and constants used or supposed in XS/C.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
