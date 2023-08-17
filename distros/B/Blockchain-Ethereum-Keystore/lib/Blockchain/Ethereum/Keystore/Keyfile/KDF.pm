use v5.26;
use Object::Pad;

package Blockchain::Ethereum::Keystore::Keyfile::KDF 0.002;
class Blockchain::Ethereum::Keystore::Keyfile::KDF;

use Crypt::PBKDF2;
use Crypt::ScryptKDF qw(scrypt_raw);

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

    my $derived_key = Crypt::PBKDF2->new(
        # currently only hmac-sha256 is supported by keyfiles
        hash_class => 'HMACSHA2',
        iterations => $self->c,
        output_len => $self->dklen,
    )->PBKDF2(pack("H*", $self->salt), $password);

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
