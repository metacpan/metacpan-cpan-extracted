use strict;
use warnings;
package Dancer::Session::Memcached::JSON;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Session store in memcached with JSON serialization

use base 'Dancer::Session::Abstract';

use JSON;
use Cache::Memcached;
use Function::Parameters qw(:strict);
use Encode qw(encode_utf8 decode_utf8);
use Dancer::Config qw(setting);

use Dancer::Session::Memcached::JSON::Signature qw(sign unsign);

my $MEMCACHED;
my $secret;

sub init {
    my ($class) = @_;
    my @servers = split ',', (setting('memcached_servers') // '');

    $class->SUPER::init;
    $secret = setting('memcached_secret');

    if(!@servers) {
        die "Invalid value for memcached_servers. Should be a comma " .
                "separated list of the form `server:port'";
    }

    $MEMCACHED = Cache::Memcached->new(servers => \@servers);
}

method update() {
    my $id = $secret
        ? unsign($self->id, $secret)
        : $self->id;

    my $data = {
        cookie => {
            path           => setting('session_cookie_path') // '/',
            httpOnly       => setting('session_is_http_only') // JSON::true,
            expires        => setting('session_expires'),
            originalMaxAge => undef
        },
    };

    map {
        $data->{$_} = $self->{$_};
    } keys %$self;

    $MEMCACHED->set($id, encode_utf8 to_json $data);
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

    my $val = $MEMCACHED->get($mid);

    if($val) {
        $val = bless(from_json(decode_utf8($val)), $class);
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

    $MEMCACHED->delete($id);
}

method flush() {
    return $self->update;
}

1;

=pod

=head1 NAME

Dancer::Session::Memcached::JSON - Session store in memcached with JSON serialization

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  session: "Memcached::JSON"
  memcached_servers: "127.0.0.1:11211,10.0.0.5:11211"

=head1 DESCRIPTION

This module implements a session store on top of Memcached. All data is
converted to JSON before being sent to Memcached, which prevents invocations of
C<Storable::nfreeze>. This common format allows the data to be shared among web
applications written in different languages.

If C<memcached_secret> is specified, all generated session IDs will be of the
form C<id.base64_mac>. This is to maintain compatibility with the session store
mechanism that L<Express|http://expressjs.com/> uses.

=head1 NAME

Dancer::Session::Memcached::JSON

=head1 AUTHOR

Forest Belton <forest@homolo.gy>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Forest Belton.

This is free software, licensed under:

  The MIT (X11) License

=cut

__END__;

