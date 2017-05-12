package Cache::Memcached::AnyEvent::Serializer::Storable;
use strict;
use Storable ();

sub new {
    my $class = shift;
    bless +{ @_ }, $class;
}

sub serialize {
# XXX Micro optimization for this:
#    my ($self, $value_ref, $len_ref, $flags_ref) = @_;
    ${$_[1]}  = Storable::nfreeze(${$_[1]});
    ${$_[2]}  = bytes::length(${$_[1]});
    ${$_[3]} |= Cache::Memcached::AnyEvent::F_SERIALIZE();
}

sub deserialize {
    ${$_[1]} = Storable::thaw(${$_[1]});
}

1;
