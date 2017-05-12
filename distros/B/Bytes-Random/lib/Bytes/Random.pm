
package Bytes::Random;

use 5.006000;
use strict;
use warnings;
use bytes;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	random_bytes
);

our $VERSION = '0.02';


#==============================================================================
sub random_bytes
{
  my $number = shift;
  return '' unless $number > 0;
  
  my @out = ( );
  for( 1..$number )
  {
    my $rand = int( rand() * 256 );
    push @out, chr( $rand );
  }# end for()
  
  return join '', @out;
}# end random_bytes()

1;# return true:

=pod

=head1 NAME

Bytes::Random - Perl extension to generate random bytes.

=head1 SYNOPSIS

  use Bytes::Random;
  
  my $bytes = random_bytes( $number_of_bytes );

=head1 DESCRIPTION

C<Bytes::Random> provides the C<random_bytes($num)> function.  It can be used 
anytime you need to generate a string of random bytes of a specific length.

=head2 EXPORT

=head3 random_bytes( $number_of_bytes )

Returns a string containing as many random bytes as was requested.


=head1 AUTHOR

John Drago, E<lt>jdrago_999@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 John Drago - All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

