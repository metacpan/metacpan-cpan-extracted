package Crypt::HSM::Sign;
$Crypt::HSM::Sign::VERSION = '0.025';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 ongoing signing operation.

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Sign - A PKCS11 ongoing signing operation.

=head1 VERSION

version 0.025

=head1 SYNOPSIS

 my $stream = $session->open_sign('rsa-pkcs-pss', $key);
 for my $chunk (@chunks) {
   $stream->add_data($chunk);
 }
 my $signature = $stream->finish;

=head1 DESCRIPTION

This class represents a signing stream.

=head1 METHODS

=head2 add_data($plaintext)

This adds data to the signing.

=head2 finalize()

This finished the signing and returns the signature.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
