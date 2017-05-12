package Cache::Memcached::AnyEvent::Serializer::JSON;
use strict;
use Module::Runtime ();
BEGIN {
    my $backend;
    foreach my $module (qw(JSON JSON::XS JSON::PP)) {
        eval { Module::Runtime::require_module($module) };
        if (! $@) {
            $backend = $module;
            last;
        }
    }
    if (! $backend) {
        die "Could not find JSON backend module";
    }

    {
        no strict 'refs';
        *_encode_json = \&{"${backend}::encode_json"};
        *_decode_json = \&{"${backend}::decode_json"};
    }
}

sub new {
    my $class = shift;
    bless +{ @_ }, $class;
}

sub serialize {
# XXX Micro optimization for this:
#    my ($self, $value_ref, $len_ref, $flags_ref) = @_;
    ${$_[1]}  = _encode_json(${$_[1]});
    ${$_[2]}  = bytes::length(${$_[1]});
    ${$_[3]} |= Cache::Memcached::AnyEvent::F_SERIALIZE();
}

sub deserialize {
    ${$_[1]} = _decode_json(${$_[1]});
}

1;