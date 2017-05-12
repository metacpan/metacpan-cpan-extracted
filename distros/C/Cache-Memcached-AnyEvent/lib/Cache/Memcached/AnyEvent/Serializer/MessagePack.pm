package Cache::Memcached::AnyEvent::Serializer::MessagePack;
use strict;
use Data::MessagePack ();

sub new {
    my $class = shift;
    bless +{ @_, packer => Data::MessagePack->new }, $class;
}

sub serialize {
# XXX Micro optimization for this:
#    my ($self, $value_ref, $len_ref, $flags_ref) = @_;
    ${$_[1]}  = $_[0]->{packer}->pack(${$_[1]});
    ${$_[2]}  = bytes::length(${$_[1]});
    ${$_[3]} |= Cache::Memcached::AnyEvent::F_SERIALIZE();
}

sub deserialize {
    ${$_[1]} = $_[0]->{packer}->unpack(${$_[1]});
}

1;