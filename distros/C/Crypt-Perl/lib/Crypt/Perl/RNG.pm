package Crypt::Perl::RNG;

use strict;
use warnings;

use Bytes::Random::Secure::Tiny ();

my %PID_RNG;

sub _get {
    return $PID_RNG{$$} ||= Bytes::Random::Secure::Tiny->new();
}

sub bytes {
    return _get()->bytes(@_);
}

sub bytes_hex {
    return _get()->bytes_hex(@_);
}

sub bit_string {
    my ($count) = @_;

    return _get()->string_from('01', $count);
}

1;
