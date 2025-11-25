package Crypt::HSM::Decrypt;
$Crypt::HSM::Decrypt::VERSION = '0.025';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 ongoing decryption operation.

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Decrypt - A PKCS11 ongoing decryption operation.

=head1 VERSION

version 0.025

=head1 SYNOPSIS

 my $stream = $session->open_decrypt('aes-gcm', $key, $iv);
 my $plaintext;
 for my $chunk (@chunks) {
   $plaintext .= $stream->add_data($chunk);
 }
 $plaintext .= $stream->finish;

=head1 DESCRIPTION

This class represents a decrypting stream.

=head1 METHODS

=head2 add_data($plaintext)

This adds data to the decryption, and returns plaintext.

=head2 finalize()

This finished the decryption, and returns and remaining plaintext.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
