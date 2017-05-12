package Crypt::Keyczar::HmacKey;
use base 'Crypt::Keyczar::Key';
use strict;
use warnings;

use Crypt::Keyczar qw(KEY_HASH_SIZE);
use Crypt::Keyczar::Util;


sub expose {
    my $self = shift;
    my $expose = {};
    $expose->{hmacKeyString} = $self->{hmacKeyString};
    $expose->{size}          = $self->{size};
    return $expose;
}



sub get_bytes {
    return Crypt::Keyczar::Util::decode($_[0]->{hmacKeyString});
}


sub digest_size {
    return 20;
}


sub init {
    my $self = shift;
    my $rawkey = $self->get_bytes;
    my $hash = Crypt::Keyczar::Util::hash($rawkey);
    $self->hash(substr $hash, 0, KEY_HASH_SIZE());
    return $self;
}


sub generate {
    my $class = shift;
    my $size = shift;

    my $self = $class->new;
    $self->{size} = $size || 256;

    my $raw = Crypt::Keyczar::Util::random($self->{size}/8);
    $self->{hmacKeyString} = Crypt::Keyczar::Util::encode($raw);
    $self->init();
    return $self;
}


sub read {
    my $class = shift;
    my $json_string = shift;

    my $obj = Crypt::Keyczar::Util::decode_json($json_string);
    my $self = bless $obj, $class;
    $self->init();
    return $self;
}


sub get_engine {
    my $self = shift;
    return Crypt::Keyczar::HmacEngine->new('sha1', $self->get_bytes);
}

1;


package Crypt::Keyczar::HmacEngine;
use base 'Exporter';
use strict;
use warnings;
use Crypt::Keyczar::Engine;


1;
__END__
