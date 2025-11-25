package Crypt::HSM::Digest;
$Crypt::HSM::Digest::VERSION = '0.025';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 ongoing digesting operation.

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Digest - A PKCS11 ongoing digesting operation.

=head1 VERSION

version 0.025

=head1 SYNOPSIS

 my $stream = $session->open_digest('aes-gcm', $key, $iv);
 for my $chunk (@chunks) {
   $stream->add_data($chunk);
 }
 my $digest = $stream->finish;

=head1 DESCRIPTION

This class represents a digestion stream.

=head1 METHODS

=head2 add_data($plaintext)

This adds data to the digestion.

=head2 add_key($key)

This adds the value of the identifier C<$key> to the digest.

=head2 finalize()

This finished the digestion and returns the digest.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
