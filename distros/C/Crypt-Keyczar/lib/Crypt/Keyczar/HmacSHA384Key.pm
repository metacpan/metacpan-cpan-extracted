package Crypt::Keyczar::HmacSHA384Key;
use base 'Crypt::Keyczar::HmacKey';
use strict;
use warnings;



sub digest_size { return 48 }


sub get_engine {
    my $self = shift;
    return Crypt::Keyczar::HmacEngine->new('sha384', $self->get_bytes);
}

1;
__END__
