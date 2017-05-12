package Crypt::Keyczar::AesKey;
use base 'Crypt::Keyczar::Key';
use strict;
use warnings;

use Crypt::Keyczar qw(KEY_HASH_SIZE);
use Crypt::Keyczar::HmacKey;

use constant DEFAULT_MODE => 'CBC';


sub expose {
    my $self = shift;
    my $expose = {};
    $expose->{aesKeyString} = $self->{aesKeyString};
    $expose->{hmacKey} = $self->{hmacKey}->expose;
    $expose->{mode} = $self->{mode};
    $expose->{size} = $self->{size};
    return $expose;
}


sub get_bytes { return Crypt::Keyczar::Util::decode($_[0]->{aesKeyString}) }


sub read {
    my $class = shift;
    my $json_string = shift;

    my $obj = Crypt::Keyczar::Util::decode_json($json_string);
    my $self = bless $obj, $class;
    $self->{hmacKey} = bless $self->{hmacKey}, 'Crypt::Keyczar::HmacKey';
    $self->{hmacKey}->init();
    $self->init();
    return $self;
}


sub init {
    my $self = shift;
    my $key = Crypt::Keyczar::Util::decode($self->{aesKeyString});
    my $hash = Crypt::Keyczar::Util::hash(pack('N1', length $key), $key, $self->{hmacKey}->get_bytes());
    $self->hash(substr $hash, 0, KEY_HASH_SIZE());
    return $self;
}


sub generate {
    my $class = shift;
    my $size = shift || 128;
    my $self = $class->new;
    $self->{size} = $size;
    my $raw = Crypt::Keyczar::Util::random($self->{size} / 8);
    $self->{aesKeyString} = Crypt::Keyczar::Util::encode($raw);
    $self->{mode} = DEFAULT_MODE;
    $self->{hmacKey} = Crypt::Keyczar::HmacKey->generate();
    return $self->init;
}


sub get_engine {
    my $self = shift;
    return Crypt::Keyczar::AesEngine->new($self->get_bytes); 
}


sub get_sign_engine {
    my $self = shift;
    return $self->{hmacKey}->get_engine;
}

1;

package Crypt::Keyczar::AesEngine;
use base 'Exporter';
use strict;
use warnings;
use Crypt::Keyczar::Engine;


1;
__END__
