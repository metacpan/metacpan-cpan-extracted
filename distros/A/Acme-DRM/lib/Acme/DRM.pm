package Acme::DRM;

use warnings;
use strict;

use vars qw(@ISA @EXPORT_OK $VERSION);

=head1 NAME

Acme::DRM - Library providing cryptographic capabilities especially suited for Digital Rights Management. Protects against Pirates.  May increase global warming. Note: Not guaranteed to protect against Pirates or increase global warming.

=head1 VERSION

Version 0.03

=cut

$VERSION = '0.03';

=head1 SYNOPSIS

 use Acme::DRM qw(secureXOR doubleROT128);
 my $intellectualProperty = 'One-hit Wonder Music';

 # Encrypt your IP to plug the digital hole
 my $encryptedContent = secureXOR($intellectualProperty);

 # Invoke the DMCA by encrypting your data, without invoking 
 # additional overhead for decryption at runtime
 my $protectedContent = doubleROT128($intellectualProperty);

=cut

=head1 EXPORT

=cut

require Exporter;
@ISA = qw(Exporter);

=over 4

=item B<secureXOR>

=cut

push( @EXPORT_OK, '&secureXOR' );

=item B<doubleROT128>

=cut

push( @EXPORT_OK, '&doubleROT128' );

=back

=head1 FUNCTIONS

=head2 secureXOR

XOR is an extremely convenient method for encrypting a digital media stream.  Given any two of the a) original data, b) encryption key, and c) encrypted data, you get the third item.  Unfortunately, hackers have compromised the effectiveness of this computationally convenient method.  The weakness is the reuse of a single key.
The answer is to use a variable key, however, key distribution becomes a difficult proposition.  If the key is distributed in the clear, pirates can simply decrypt the digital media stream, and steal your B<Intellectual Property>.  Our solution is to use the media itself as the key.  This function conveniently takes only the media as a single argument, and automatically XORs the datastream with a copy of itself, rendering the stream almost completely unrecoverable without the key: the media itself.  This is virtually hacker-proof, except for one exception:  the encrypted datastream is exactly the same length as the original data, but this is almost never probably a weakness.  This algorithm does guarantee that your original data will not be recoverable from the encrypted stream without the proper key.  Additionally, use of an incorrect key will not provide hackers with any sort of clue that they have guessed an incorrect key.

=cut

sub secureXOR {

  # Get the first argument
  my $data = shift;

  # Make sure we really got something
  unless ( defined($data) ) {
    return;
  }

  # Where we'll collect the output
  my @output;

  # Break the data into individual bytes
  my @data = unpack( 'C*', $data );

  # Iterate over each byte
  for my $byte (@data) {

    # Protect each byte with the secure variable-key
    # XOR algorithm
    push( @output, $byte ^ $byte );
  }

  # Re-encode the encrypted data and output it as a single stream
  return ( pack( 'C*', @output ) );
}

=head2 doubleROT128

This function exists to provide a method by which you can protect your B<Intellectual Property> under the DMCA, without imposing the difficulty of implementing a separate, potentially insecure decryption algorithm in your secure media playback application.
Simply pass your digital media to this function, and it will output an encrypted stream, conveniently passed twice internally through a strong ROT-128 encryption algorithm.  The resulting encrypted content cannot be legally decrypted by a hacker, since you encrypted it to protect it from hackers and pirates.  Further, you can pass the content through this algorithm multiple times for enhanced protection.  Decryption can be performed by either passing the encrypted datastream back through this algorithm, or in many cases, the encrypted stream itself can be used by the playback function.

=cut

sub doubleROT128 {

  # Get the first argument
  my $data = shift;

  # Make sure we got something
  unless ( defined($data) ) {
    return;
  }

  # Where to keep the output as individual bytes
  my @output;

  # Break the input into individual bytes
  my @data = unpack( 'C*', $data );

  # Protect each byte individually, and accumulate the results
  for my $byte (@data) {

    # Marvel at the beauty of this algorithm

    # Left shift 4 bits -- this makes the number 12 bits, lower 4 bits are all 0
    $byte = $byte << 4;

    # Rotate the high 4 bits back around to make this an 8-bit value again
    $byte = ( $byte / 2**8 ) + ( $byte % 2**8 );

    # Now rotate it again for twice the security
    $byte = $byte << 4;
    $byte = ( $byte / 2**8 ) + ( $byte % 2**8 );

    # And collect the output
    push( @output, $byte );
  }

  # Re-encode the encrypted stream and output it
  return ( pack( 'C*', @output ) );
}

=head1 AUTHOR

Brett T. Warden, C<< <bwarden-cpan@wgz.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-drm@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-DRM>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to the lobbyists behind the DMCA and the politicians who bought (or
were bought) into the great idea of assigning corporate greed higher value
than constitutionally-asserted citizen rights.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2007 Brett T. Warden, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Acme::DRM
