package Crypt::Keyczar::HmacSHA512Key;
use base 'Crypt::Keyczar::HmacKey';
use strict;
use warnings;



sub digest_size { return 64 }


sub get_engine {
    my $self = shift;
    return Crypt::Keyczar::HmacEngine->new('sha512', $self->get_bytes);
}

1;
__END__
