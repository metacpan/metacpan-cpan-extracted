package Crypt::Keyczar::DsaPrivateKey;
use base 'Crypt::Keyczar::Key';
use strict;
use warnings;

use Crypt::Keyczar::Util;
use Crypt::Keyczar::DsaPublicKey;


sub expose {
    my $self = shift;
    my $expose = {};
    $expose->{size} = $self->{size};
    $expose->{publicKey} = $self->get_public->expose;
    $expose->{x} = $self->{x};
    return $expose;
}


sub read {
    my $class = shift;
    my $json_string = shift;

    my $obj = Crypt::Keyczar::Util::decode_json($json_string);
    my $self = bless $obj, $class;
    $self->{publicKey} = bless $self->{publicKey}, 'Crypt::Keyczar::DsaPublicKey';
    $self->{publicKey}->init();
    $self->init();
    return $self;
}


sub generate {
    my $class = shift;
    my $size = shift;

    my $key = Crypt::Keyczar::DsaPrivateKeyEngine->generate($size);
    my $priv = {};
    $priv->{size} = $size;
    $priv->{x} = Crypt::Keyczar::Util::encode($key->{x});
    my $self = bless $priv, $class;

    my $pub = {};
    $pub->{size} = $size;
    $pub->{y} = Crypt::Keyczar::Util::encode($key->{y});
    $pub->{p} = Crypt::Keyczar::Util::encode($key->{p});
    $pub->{q} = Crypt::Keyczar::Util::encode($key->{q});
    $pub->{g} = Crypt::Keyczar::Util::encode($key->{g});
    $self->{publicKey} = bless $pub, 'Crypt::Keyczar::DsaPublicKey';
    $self->{publicKey}->init();
    $self->init();

    return $self;
}


sub get_engine {
    my $self = shift;
    my @args = map { Crypt::Keyczar::Util::decode($_) } (
        $self->{x},
        $self->get_public->{y},
        $self->get_public->{p},
        $self->get_public->{q},
        $self->get_public->{g},
    );
    return Crypt::Keyczar::DsaPrivateKeyEngine->new(@args);
}


sub hash { return $_[0]->get_public->hash(); }


sub digest_size { return 48; }


sub get_public { return $_[0]->{publicKey}; }

1;

package Crypt::Keyczar::DsaPrivateKeyEngine;
use base 'Exporter';
use strict;
use warnings;
use Crypt::Keyczar::Engine;


1;
__END__
