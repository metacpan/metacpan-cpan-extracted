package Crypt::Keyczar::HmacSHA256Key;
use base 'Crypt::Keyczar::HmacKey';
use strict;
use warnings;



sub digest_size { return 32 }


sub get_engine {
    my $self = shift;
    return Crypt::Keyczar::HmacEngine->new('sha256', $self->get_bytes);
}

1;
__END__
