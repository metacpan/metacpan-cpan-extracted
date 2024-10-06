use v5.26;

use strict;
use warnings;
no indirect;
use feature 'signatures';

use Object::Pad;

package Blockchain::Ethereum::Keystore::Keyfile::KDF;
class Blockchain::Ethereum::Keystore::Keyfile::KDF;

our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.010';          # VERSION

use Crypt::KeyDerivation qw(pbkdf2);
use Crypt::ScryptKDF     qw(scrypt_raw);

field $algorithm :reader :writer :param;
field $dklen :reader :writer :param;
field $n :reader :writer :param   //= undef;
field $p :reader :writer :param   //= undef;
field $r :reader :writer :param   //= undef;
field $prf :reader :writer :param //= undef;
field $c :reader :writer :param   //= undef;
field $salt :reader :writer :param;

method decode ($password) {

    my $kdf_function = '_decode_kdf_' . $self->algorithm;
    return $self->$kdf_function($password);
}

method _decode_kdf_pbkdf2 ($password) {

    my $derived_key = pbkdf2($password, pack("H*", $self->salt), $self->c, 'SHA256', $self->dklen);

    return $derived_key;
}

method _decode_kdf_scrypt ($password) {

    my $derived_key = scrypt_raw(
        $password,    #
        pack("H*", $self->salt),
        $self->n,
        $self->r,
        $self->p,
        $self->dklen
    );

    return $derived_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Keystore::Keyfile::KDF

=head1 VERSION

version 0.010

=head1 AUTHOR

Reginaldo Costa <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
