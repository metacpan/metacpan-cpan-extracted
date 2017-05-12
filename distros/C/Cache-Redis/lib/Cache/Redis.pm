package Cache::Redis;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.13';

use Module::Load;

my $_mp;
sub _mp {
    $_mp ||= Data::MessagePack->new->utf8;
}
sub _mp_serialize {
    _mp->pack(@_);
}
sub _mp_deserialize {
    _mp->unpack(@_);
}

sub _mk_serialize {
    my $code = shift;

    return sub {
        my $data = shift;

        my $flags; # for future extention
        my $store_date = [$data, $flags];
        $code->($store_date);
    };
}

sub _mk_deserialize {
    my $code = shift;

    return sub {
        my $data = shift;

        my ($org, $flags) = @{$code->($data)};
        $org;
    };
}

sub new {
    my $class = shift;

    my $args = @_ == 1 ? $_[0] : {@_};
    my $default_expires_in = delete $args->{default_expires_in} || 60*60*24 * 30;
    my $namespace          = delete $args->{namespace}          || '';
    my $nowait             = delete $args->{nowait}             || 0;
    my $redis_class        = delete $args->{redis_class}        || 'Redis';

    my $redis             = delete $args->{redis};
    my $serializer        = delete $args->{serializer};
    my $serialize_methods = delete $args->{serialize_methods};
    die '`serializer` and `serialize_methods` is exclusive option' if $serializer && $serialize_methods;
    $serializer ||= 'Storable' unless $serialize_methods;

    my ($serialize, $deserialize);
    if ($serializer) {
        if ($serializer eq 'Storable') {
            require Storable;
            $serialize_methods = [\&Storable::nfreeze, \&Storable::thaw];
        }
        elsif ($serializer eq 'JSON') {
            require JSON::XS;
            $serialize_methods = [\&JSON::XS::encode_json, \&JSON::XS::decode_json];
        }
    }

    if ($serialize_methods) {
        $serialize   = _mk_serialize   $serialize_methods->[0];
        $deserialize = _mk_deserialize $serialize_methods->[1];
    }
    elsif ($serializer eq 'MessagePack') {
        require Data::MessagePack;
        $serialize   = \&_mp_serialize;
        $deserialize = \&_mp_deserialize;
    }
    die 'Serializer is not found' if !$serialize || !$deserialize;

    unless ( $redis ) {
        load $redis_class;
        $redis = $redis_class->new(
            encoding => undef,
            %$args
        );
    }

    bless {
        default_expires_in => $default_expires_in,
        serialize          => $serialize,
        deserialize        => $deserialize,
        redis              => $redis,
        namespace          => $namespace,
        nowait             => $nowait,
    }, $class;
}

sub get {
    my ($self, $key) = @_;
    $key = $self->{namespace} . $key;

    my $data = $self->{redis}->get($key);

    defined $data ? $self->{deserialize}->($data) : $data;
}

sub get_multi {
    my ($self, @keys) = @_;
    @keys = map { $self->{namespace} . $_ } @keys;

    my @data = $self->{redis}->mget(@keys);

    my $i = 0;
    my $ret = {};
    for my $key ( @keys ) {
        if ( defined $data[$i] ) {
            $ret->{$key} = $self->{deserialize}->($data[$i]);
        }
        $i++;
    }

    $ret;
}

sub set {
    my ($self, $key, $value, $expire, $callback) = @_;

    die 'set() requires key and value arguments' if scalar(@_) < 3;

    my $response = $self->_set($key, $value, $expire, $callback);

    # return now as the callabck will be called when it's done processing
    return if ($self->{nowait});
    $self->{redis}->wait_all_responses;
    return $response;
}

sub set_multi {
    my ($self, @items) = @_;

    for my $item ( @items ) {
        $self->_set(@$item);
    }
    $self->{redis}->wait_all_responses unless $self->{nowait};
}

sub _set {
    my ($self, $key, $value, $expire, $callback) = @_;
    $key = $self->{namespace} . $key;
    $expire ||= $self->{default_expires_in};

    if ($self->{nowait} && $callback) {
      $self->{redis}->setex($key, $expire, $self->{serialize}->($value), $callback);
    }
    else {
      $self->{redis}->setex($key, $expire, $self->{serialize}->($value));
    }
}

sub get_or_set {
    my ($self, $key, $code, $expire) = @_;

    my $data = $self->get($key);
    unless (defined $data) {
        $data = $code->();
        $self->set($key, $data, $expire);
    }
    $data;
}

sub remove {
    my ($self, $key) = @_;

    my $data = $self->get($key);
    $key = $self->{namespace} . $key;
    $self->{redis}->del($key);

    $data;
}

sub nowait_push {
    shift->{redis}->wait_all_responses;
}

1;
__END__

=head1 NAME

Cache::Redis - Redis client specialized for cache

=head1 SYNOPSIS

    use Cache::Redis;

    my $cache = Cache::Redis->new(
        server    => 'localhost:9999',
        namespace => 'cache:',
    );
    $cache->set('key', 'val');
    my $val = $cache->get('key');
    $cache->remove('key');


=head1 DESCRIPTION

This module is for cache of Redis backend having L<Cache::Cache> like interface.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 INTERFACE

=head2 Methods

=head3 C<< my $obj = Cache::Redis->new(%options) >>

Create a new cache object. Various options may be set in C<%options>, which affect
the behaviour of the cache (defaults in parentheses):

=over

=item C<redis>

Instance of Redis class are used as backend. If this is not passed, L<Cache::Redis> load from C<redis_class> automatically.

=item C<redis_class ('Redis')>

The class for backend.

=item C<default_expires_in (60*60*24 * 30)>

The default expiration seconds for objects place in the cache.

=item C<namespace ('')>

The namespace associated with this cache.

=item C<nowait (0)>

If enabled, when you call a method that only returns its success status (like "set"), in a void context,
it sends the request to the server and returns immediately, not waiting the reply. This avoids the
round-trip latency at a cost of uncertain command outcome.

=item C<serializer ('Storable')>

Serializer. 'MessagePack' and 'Storable' are usable. if `serialize_methods` option
is specified, this option is ignored.

=item C<serialize_methods (undef)>

The value is a reference to an array holding two code references for serialization and
de-serialization routines respectively.

=item server (undef)

Redis server information. You can use `sock` option instead of this and can specify
all other L<Redis> constructor options to C<< Cache::Cache->new >> method.

=back

=head3 C<< $obj->set($key, $value, $expire) >>

Set a stuff to cache.

=head3 C<< $obj->set_multi([$key, $value, $expire], [$key, $value]) >>

Set multiple stuffs to cache. stuffs is array reference.

=head3 C<< my $stuff = $obj->get($key) >>

Get a stuff from cache.

=head3 C<< my $res = $obj->get_multi(@keys) >>

Get multiple stuffs as hash reference from cache. C<< @keys >> should be array.
A key is not stored on cache don't be contain C<< $res >>.

=head3 C<< $obj->remove($key) >>

Remove stuff of key from cache.

=head3 C<< $obj->get_or_set($key, $code, $expire) >>

Get a cache value for I<$key> if it's already cached. If it's not cached then,
run I<$code> and cache I<$expiration> seconds and return the value.

=head3 C<< $obj->nowait_push >>

Wait all response from Redis. This is intended for C<< $obj->nowait >>.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
