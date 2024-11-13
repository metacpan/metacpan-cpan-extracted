package Crypt::HSM;
$Crypt::HSM::VERSION = '0.019';
use strict;
use warnings;

use XSLoader;
XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: A PKCS11 interface for Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM - A PKCS11 interface for Perl

=head1 VERSION

version 0.019

=head1 SYNOPSIS

 my $hsm = Crypt::HSM->load('/usr/lib/pkcs11/libsofthsm2.so');
 my ($slot) = $hsm->slots;
 my $session = $slot->open_session;
 $session->login('user', '1234');

 my ($key) = $session->find_objects({ class => 'secret-key', label => "my-key" });
 my $ciphertext = $session->encrypt('aes-gcm', $key, $plaintext, $iv);

=head1 DESCRIPTION

This module interfaces with any PKCS11 library to use its cryptography.

=head1 METHODS

=head2 load($path)

This loads the pkcs11 found a $path, and returns it as a new L<Crypt::HSM::Provider|Crypt::HSM::Provider> object.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
