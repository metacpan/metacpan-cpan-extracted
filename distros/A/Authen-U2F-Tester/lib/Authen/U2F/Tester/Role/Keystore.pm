#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::Role::Keystore;
$Authen::U2F::Tester::Role::Keystore::VERSION = '0.02';
# ABSTRACT: U2F Tester Keystore Role.

use Moose::Role;


requires qw(exists put get remove);

1;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::Role::Keystore - U2F Tester Keystore Role.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 package Authen::U2F::Tester::Keystore::Example;

 use Moose;
 use namespace::autoclean;

 with 'Authen::U2F::Tester::Role::Keystore';

 sub exists {
     my ($self, $handle) = @_;
     ...
     # if handle is valid and exists in the keystore:
     return 1;

     # else
     return 0;
 }

 sub put {
     my ($self, $private_key) = @_;

     # somehow generate a unique handle
     return $handle;
 }

 sub get {
     my ($self, $handle) = @_;

     $handle = decode_base64url($handle);

     # fetch the Crypt::PK::ECC private key object associated with this handle.
     return $pkec;
 }

 __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This is a L<Moose::Role> that L<Authen::U2F::Tester> keystore's must consume.
All required methods must be implemented by the consuming L<Moose> class.

=head1 METHODS

=head2 exists($handle): bool

Check if the given handle (in Base64 URL format) exists (or is valid) in the key store.

=head2 get($handle): Crypt::PK::ECC

Given the key handle (in Base64 URL format), return the private key (as a
L<Crypt::PK::ECC> object) associated with it in the key store.

=head2 put($private_key): scalar

Save the given keypair in the keystore, returning a unique key handle that
uniquely identifies the keypair.  The returned handle should B<NOT> be Base64
URL encoded.  C<$private_key> is a raw private key string.

=head2 remove($handle): void

Remove the given key handle from the key store.

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/perl-authen-u2f-tester>
and may be cloned from L<git://github.com/mschout/perl-authen-u2f-tester.git>

=head1 BUGS

Please report any bugs or feature requests to bug-authen-u2f-tester@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Authen-U2F-Tester

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
