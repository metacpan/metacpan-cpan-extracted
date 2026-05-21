package Archive::Lha::CRC;

use strict;
use warnings;
use Archive::Lha;  # to load XS

1;

__END__

=head1 NAME

Archive::Lha::CRC

=head1 SYNOPSIS

  use bytes;
  $crc = Archive::Lha::CRC::update( $crc, $str, length($str) );

=head1 DESCRIPTION

This provides one utility function to calculate CRC-16, well, reversed CRC-16-IBM (X^16 + X^15 + X^2 + 1, not 0x8005 but 0xA001 one).

=head1 METHODS

=head2 update

takes a previous value, a string, the length of the string in bytes, and returns the updated CRC-16 value. Note that this is a thin wrapper of a C function and you actually need to pass the length in bytes, in other words, sizeof(unsigned char). If you get a wrong value, check your input callback you pass to the Archive::Lha::Decode object. Your archive may be broken, but most probably you've converted something (say, the ends of line) to your (or your system's) taste implicitly.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
