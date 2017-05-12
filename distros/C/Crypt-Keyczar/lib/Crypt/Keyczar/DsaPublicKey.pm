package Crypt::Keyczar::DsaPublicKey;
use base 'Crypt::Keyczar::Key';
use strict;
use warnings;

use Crypt::Keyczar qw(KEY_HASH_SIZE);
use Crypt::Keyczar::Util;



sub expose {
    my $self = shift;
    my $expose = {};
    $expose->{y} = $self->{y};
    $expose->{p} = $self->{p};
    $expose->{q} = $self->{q};
    $expose->{g} = $self->{g};
    $expose->{size} = $self->{size};
    return $expose;
}


sub read {
    my $class = shift;
    my $json_string = shift;

    my $obj = Crypt::Keyczar::Util::decode_json($json_string);
    my $self = bless $obj, $class;
    $self->init();
    return $self;
}


sub init {
    my $self = shift;
    my $y = Crypt::Keyczar::Util::decode($self->{y});
    my $p = Crypt::Keyczar::Util::decode($self->{p});
    my $q = Crypt::Keyczar::Util::decode($self->{q});
    my $g = Crypt::Keyczar::Util::decode($self->{g});
    $y =~ s/^\x00+//;
    $p =~ s/^\x00+//;
    $q =~ s/^\x00+//;
    $g =~ s/^\x00+//;
    my $hash = Crypt::Keyczar::Util::hash(
        pack('N1', length $p), $p,
        pack('N1', length $q), $q,
        pack('N1', length $g), $g,
        pack('N1', length $y), $y);
    $self->hash(substr $hash, 0, KEY_HASH_SIZE());
}


sub set {
    my $self = shift;
    my ($y, $p, $q, $g) = @_;
    $self->{y} = $y;
    $self->{p} = $p;
    $self->{q} = $q;
    $self->{g} = $g;
    $self->init();
    return $self;
}


sub digest_size { return 48; }


sub get_engine {
    my $self = shift;
    my @args = map { Crypt::Keyczar::Util::decode($_) } ($self->{y}, $self->{p}, $self->{q}, $self->{g});
    return Crypt::Keyczar::DsaPublicKeyEngine->new(@args);
}


1;

package Crypt::Keyczar::DsaPublicKeyEngine;
use base 'Exporter';
use strict;
use warnings;
use Crypt::Keyczar::Engine;


1;
__END__
