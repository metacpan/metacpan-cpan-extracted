package Crypt::HSM::Verify;
$Crypt::HSM::Verify::VERSION = '0.016';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 ongoing verification operation.

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Verify - A PKCS11 ongoing verification operation.

=head1 VERSION

version 0.016

=head1 SYNOPSIS

 my $stream = $session->open_verify('rsa-pkcs-pss', $key, $iv);
 for my $chunk (@chunks) {
   $stream->add_data($chunk);
 }
 my $success = $stream->finish($signature);

=head1 DESCRIPTION

This class represents a verification stream.

=head1 METHODS

=head2 add_data($plaintext)

This adds data to the verification.

=head2 finalize($signature)

This finished the verification and returns true if the calculated signature
matches C<$signature>, or false otherwise.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
