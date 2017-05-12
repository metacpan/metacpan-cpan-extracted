package Crypt::Keyczar::Key;
use strict;
use warnings;
use Carp;

use Crypt::Keyczar::Util;



my %POLICY = (
    'AES' => {
        object => 'Crypt::Keyczar::AesKey',
        keysize => [128, 192, 256],
        outsize => 0
    },
    'HMAC_SHA1' => {
        object => 'Crypt::Keyczar::HmacKey',
        keysize => [256],
        outsize => 20
    },
    'DSA_PRIV' => {
        object => 'Crypt::Keyczar::DsaPrivateKey',
        keysize => [1024],
        outsize => 48
    },
    'DSA_PUB' => {
        object => 'Crypt::Keyczar::DsaPublicKey',
        keysize => [1024],
        outsize => 48
    },
    'RSA_PRIV' => {
        object => 'Crypt::Keyczar::RsaPrivateKey',
        keysize => [4096, 2048, 1024, 768, 512],
        outsize => 256
    },
    'RSA_PUB' => {
        object => 'Crypt::Keyczar::RsaPublicKey',
        keysize => [4096, 2048, 1024, 768, 512],
        outsize => 256
    },

    'HMAC_SHA224' => {
        object => 'Crypt::Keyczar::HmacSHA224Key',
        keysize => [256],
        outsize => 28
    },
    'HMAC_SHA256' => {
        object => 'Crypt::Keyczar::HmacSHA256Key',
        keysize => [256],
        outsize => 32 
    },
    'HMAC_SHA384' => {
        object => 'Crypt::Keyczar::HmacSHA384Key',
        keysize => [256],
        outsize => 48
    },
    'HMAC_SHA512' => {
        object => 'Crypt::Keyczar::HmacSHA512Key',
        keysize => [256],
        outsize => 64
    },
);


sub set_policy {
    my $class = shift;
    %POLICY = @_;
}


sub new {
    my $class = shift;
    return bless {}, $class;
}


sub init {}


sub get_header {
    my $self = shift;
    return pack 'C1 a*', Crypt::Keyczar::FORMAT_VERSION(), $self->hash();
}

sub expose {
    my $self = shift;
    my $expose = {};
    $expose->{size} = $self->{size};
    return $expose;
}


sub hash {
    my $self = shift;
    $self->{__hash} = shift if @_;
    return $self->{__hash};
}


sub get_size {}
sub get_type {}
sub get_engine {}
sub get_sign_engine { return Crypt::Keyczar::_NullSignEngine->new(); }



sub generate_key {
    my $class = shift;
    my ($type, $size) = @_;

    if (!exists $POLICY{uc $type}) {
        croak "unsupported key type: $type";
    }

    my $key = $POLICY{uc $type}->{object};
    eval "use $key";
    if ($@) {
        croak "$type: $@";
    }
    if ($size) {
        if (scalar(grep {$_ == $size} @{$POLICY{uc $type}->{keysize}}) == 0) {
            croak "unacceptable key size: $size\@$type";
        }
    }
    else {
        $size = $POLICY{uc $type}->{keysize}->[0]; # set default key size
    }
    return $key->generate($size);
}


sub read_key {
    my $class = shift;
    my ($type, $json_string_key) = @_;

    if (!exists $POLICY{uc $type}) {
        croak "unsupported key type: $type";
    }
    my $key = $POLICY{uc $type}->{object};
    eval "use $key";
    if ($@) {
        croak "$type: $@";
    }
    return $key->read($json_string_key);
}


sub to_string {
    return Crypt::Keyczar::Util::encode_json($_[0]->expose);
}

1;


package Crypt::Keyczar::_NullSignEngine;
use strict;
use warnings;

sub new { return bless {}, $_[0]; }
sub digest_size { return 0 }
sub init { return '' }
sub update {}
sub sign { return '' }
sub verify { return 1 }



__END__
