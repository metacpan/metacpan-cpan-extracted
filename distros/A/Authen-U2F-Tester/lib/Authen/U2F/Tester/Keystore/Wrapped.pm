#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester::Keystore::Wrapped;
$Authen::U2F::Tester::Keystore::Wrapped::VERSION = '0.03';
# ABSTRACT: Wrapped Keystore for Authen::U2F::Tester

use Moose;
use Crypt::PK::ECC;
use MIME::Base64 qw(decode_base64url);
use namespace::autoclean;

with 'Authen::U2F::Tester::Role::Keystore';

has key => (is => 'ro', isa => 'Crypt::PK::ECC', required => 1);

sub exists {
    my ($self, $handle) = @_;

    $handle = decode_base64url($handle);

    if (eval { $self->key->decrypt($handle); 1 }) {
        return 1;
    }
    else {
        return 0;
    }
}

sub get {
    my ($self, $handle) = @_;

    my $private_key = $self->key->decrypt(decode_base64url($handle));

    my $pkec = Crypt::PK::ECC->new;
    $pkec->import_key_raw($private_key, 'nistp256');

    return $pkec;
}

sub put {
    my ($self, $private_key) = @_;

    my $handle = $self->key->encrypt($private_key, 'SHA256');

    return $handle;
}

sub remove {
    require Carp;
    Carp::croak 'Keys cannot be removed from the Wrapped Keystore';
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Authen::U2F::Tester::Keystore::Wrapped - Wrapped Keystore for Authen::U2F::Tester

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 my $key = Crypt::PK::ECC->new;
 ...
 my $keystore = Authen::U2F::Tester::Keystore->new(key => $key);

 my $keypair = Authen::U2F::Tester::Keypair->new;
 my $handle = $keystore->put($keypair->private_key);

 if ($keystore->exists($handle)) {
     my $pkec = $keystore->get($handle);
 }

=head1 DESCRIPTION

This is a "wrapped" key store for L<Authen::U2F::Tester>.  This is the default
key store used by L<Authen::U2F::Tester>.  This key store does not require any
backing storage at all to keep track of registered keys.  Instead, it generates
key handles by encrypting the private key using the tester's private key and
returns this encrypted value as the key handle.  This is somewhat vaguely
describe in the FIDO/U2F specifications as a "wrapped" key handle.  My
experience is that most of the U2F devices out there use some variation of this
scheme because it allows the devices to be used with an infinite number of
services as no local storage is required on the U2F device.

Storage of the key handle is not required because this class can tell if the
handle is valid or not by trying to decrypt the passed in key handle.  If
decryption succeeds, then the handle is valid.  Otherwise, the handle is not
valid.

=for Pod::Coverage exists get put remove

=head1 SEE ALSO

=over 4

=item *

L<Authen::U2F::Tester::Role::Keystore>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/mschout/perl-authen-u2f-tester>
and may be cloned from L<git://https://github.com/mschout/perl-authen-u2f-tester.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/perl-authen-u2f-tester/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
