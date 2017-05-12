package Crypt::Keyczar::RsaPrivateKey;
use base 'Crypt::Keyczar::Key';
use strict;
use warnings;

use Crypt::Keyczar::Util;
use Crypt::Keyczar::RsaPublicKey;


sub expose {
    my $self = shift;
    my $expose = {};
    $expose->{size}            = $self->{size};
    $expose->{publicKey}       = $self->get_public->expose;
    $expose->{privateExponent} = $self->{privateExponent};
    $expose->{primeP}          = $self->{primeP};
    $expose->{primeQ}          = $self->{primeQ};
    $expose->{primeExponentP}  = $self->{primeExponentP};
    $expose->{primeExponentQ}  = $self->{primeExponentQ};
    $expose->{crtCoefficient}  = $self->{crtCoefficient};
    return $expose;
}


sub read {
    my $class = shift;
    my $json_string = shift;

    my $obj = Crypt::Keyczar::Util::decode_json($json_string);
    my $self = bless $obj, $class;
    $self->{publicKey} = bless $self->{publicKey}, 'Crypt::Keyczar::RsaPublicKey';
    $self->{publicKey}->init();
    $self->init();
    return $self;
}


sub generate {
    my $class = shift;
    my $size = shift;

    my $key = Crypt::Keyczar::RsaPrivateKeyEngine->generate($size);
    my $priv = {};
    $priv->{size} = $size;
    $priv->{privateExponent} = Crypt::Keyczar::Util::encode($key->{privateExponent});
    $priv->{primeP} = Crypt::Keyczar::Util::encode($key->{primeP});
    $priv->{primeQ} = Crypt::Keyczar::Util::encode($key->{primeQ});
    $priv->{primeExponentP} = Crypt::Keyczar::Util::encode($key->{primeExponentP});
    $priv->{primeExponentQ} = Crypt::Keyczar::Util::encode($key->{primeExponentQ});
    $priv->{crtCoefficient} = Crypt::Keyczar::Util::encode($key->{crtCoefficient});
    my $self = bless $priv, $class;

    my $pub = {};
    $pub->{size} = $size;
    $pub->{modulus} = Crypt::Keyczar::Util::encode($key->{modulus});
    if (length $key->{publicExponent} < 4) {
        # padding 32bit big-endian
        my $pad = '';
        $pad .= "\x00" x (4 - length $key->{publicExponent});
        $key->{publicExponent} = $pad . $key->{publicExponent};
    }
    $pub->{publicExponent} = Crypt::Keyczar::Util::encode($key->{publicExponent});
    $self->{publicKey} = bless $pub, 'Crypt::Keyczar::RsaPublicKey'; 
    $self->{publicKey}->init();
    $self->init();

    return $self;
}


sub get_engine {
    my $self = shift;
    my @args = map { Crypt::Keyczar::Util::decode($_) } (
        $self->get_public->{modulus}, $self->get_public->{publicExponent},
        $self->{privateExponent}, $self->{primeP}, $self->{primeQ},
        $self->{primeExponentP}, $self->{primeExponentQ},
        $self->{crtCoefficient}
    );
    my $engine = Crypt::Keyczar::RsaPrivateKeyEngine->new(@args);
    $self->{_digest_size} = $engine->digest_size;
    return $engine;
}


sub hash { return $_[0]->get_public->hash(); }


sub digest_size { return $_[0]->{_digest_size}; }


sub get_public { return $_[0]->{publicKey}; }

1;

package Crypt::Keyczar::RsaPrivateKeyEngine;
use base 'Exporter';
use strict;
use warnings;
use Crypt::Keyczar::Engine;


1;
__END__
