use strict;
use warnings;
package Dancer::Session::Redis::JSON;

our $VERSION = '0.001'; # VERSION
# ABSTRACT: Session store in Redis with JSON serialization

use base 'Dancer::Session::Abstract';

use Redis;
use JSON qw(encode_json decode_json);
use Function::Parameters qw(:strict);
use Dancer::Config qw(setting);

use Dancer::Session::Redis::JSON::Signature qw(sign unsign);

my $REDIS;
my $secret;

sub init {
    my ($class) = @_;

    $class->SUPER::init;
    $secret = setting('redis_secret');
    $REDIS = Redis->new(server => setting('redis_server'));
}

method update() {
    my $id = $secret
        ? unsign($self->id, $secret)
        : $self->id;

    my $data = {
        cookie => {
            path           => setting('session_cookie_path')  // '/',
            httpOnly       => setting('session_is_http_only') // JSON::true,
            expires        => setting('session_expires'),
            originalMaxAge => undef
        },
    };

    map {
        $data->{$_} = $self->{$_};
    } keys %$self;

    $REDIS->set($id, encode_json $data);
    return $self;
}

fun create(Str $class) {
    my $self = $class->new;

    $self->{id} = sign($self->id, $secret)
        if $secret;

    return $self->update;
}

fun retrieve(Str $class, Str|Int $id) {
    my $mid = $secret
        ? unsign($id, $secret)
        : $id;

    my $val = $REDIS->get($mid);

    if($val) {
        $val = bless(decode_json($val), $class);
        $val->{id} = $id;
    } else {
        $val = create($class);
    }

    return $val;
}

method destroy() {
    my $id = $secret
        ? unsign($self->id, $secret)
        : $self->id;

    $REDIS->del($id);
}

method flush() {
    return $self->update;
}

1;

=pod

=head1 NAME

Dancer::Session::Redis::JSON - Session store in Redis with JSON serialization

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  session: "Redis::JSON"
  redis_server: "127.0.0.1:6379"

=head1 DESCRIPTION

This module implements a session store on top of Redis. All data is
converted to JSON before being sent to Redis, which prevents invocations of
C<Storable::nfreeze>. This common format allows the data to be shared among web
applications written in different languages.

If C<redis_secret> is specified, all generated session IDs will be of the
form C<id.base64_mac>. This is to maintain compatibility with the session store
mechanism that L<Express|http://expressjs.com/> uses.

=head1 NAME

Dancer::Session::Redis::JSON

=head1 AUTHOR

Forest Belton <forest@homolo.gy>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Forest Belton.

This is free software, licensed under:

  The MIT (X11) License

=cut

__END__;

