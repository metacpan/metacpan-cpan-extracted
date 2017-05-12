package Crypt::Keyczar::HmacSHA224Key;
use base 'Crypt::Keyczar::HmacKey';
use strict;
use warnings;



sub digest_size { return 28 }


sub get_engine {
    my $self = shift;
    return Crypt::Keyczar::HmacEngine->new('sha224', $self->get_bytes);
}

1;
__END__
