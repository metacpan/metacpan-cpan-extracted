package Crypt::HSM::Stream;
$Crypt::HSM::Stream::VERSION = '0.011';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 ongoing operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Stream - A PKCS11 ongoing operation

=head1 VERSION

version 0.011

=head1 SYNOPSIS

 my $stream = $session->open_encrypt('aes-cbc', $key, $iv);
 my $ciphertext;
 for my $chunk (@chunks) {
   $ciphertext .= $stream->add_data($chunk);
 }
 $ciphertext .= $stream->finish;

=head1 DESCRIPTION

This is a base-class for streaming actions.

=head1 METHODS

=head2 get_state()

Get a copy of the cryptographic operations state of this operation

=head2 set_state($state)

Set a the cryptographic operations state of this operation.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
