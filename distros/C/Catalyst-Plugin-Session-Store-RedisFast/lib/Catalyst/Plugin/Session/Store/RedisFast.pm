package Catalyst::Plugin::Session::Store::RedisFast;

use strict;
use warnings;
use utf8;

use MIME::Base64 qw/encode_base64 decode_base64/;
use Redis::Fast;
use CBOR::XS qw/encode_cbor decode_cbor/;
use Carp qw/croak/;

use base qw/
    Catalyst::Plugin::Session::Store
    Class::Data::Inheritable
    /;

our $VERSION = '0.03';

__PACKAGE__->mk_classdata(qw/_session_redis_storage/);

sub get_session_data {
    my ($c, $key) = @_;

    if (my ($sid) = $key =~ /^expires:(.*)/) {
        #Return TTL of key
        my $ttl = $c->_redis_op('ttl', "session:$sid");
        my $exp_time = time() + $ttl;
        $c->log->debug("Getting expires key for '$sid'. TTl: $ttl. Expire time: $exp_time");
        return $exp_time;
    }

    $c->log->debug("Getting '$key'");
    my $data = $c->_redis_op('get', $key) or return;

    return decode_cbor(decode_base64($data));
}

sub store_session_data {
    my ($c, $key, $value) = @_;

    if (my ($sid) = $key =~ /^expires:(.*)/) {
        # Store expires for key
        my $ttl = $value - time();
        $c->log->debug("Set expires to sid '$sid'. TTL: $ttl");

        if ($c->_redis_op('exists', "session:$sid")) {
            $c->set_session_ttl("session:$sid", $ttl);
        }
        else {
            $c->_redis_op('set', "session:$sid", '', 'EX', $ttl);
        }
        return 1;
    }

    $c->log->debug("Store session data to '$key'");
    my $ttl = $c->_redis_op('ttl', $key);
    # If key not exists
    $ttl = $c->session_expires - time() if $ttl < 0;

    # Update key with ttl
    if ($ttl > 0) {
        $c->_redis_op('set', $key, encode_base64(encode_cbor($value)), 'EX', $ttl);
    }

    return 1;
}

sub set_session_ttl {
    my ($c, $key, $ttl) = @_;
    $c->_redis_op('expire', $key, $ttl);

}

sub delete_session_data {
    my ($c, $key) = @_;

    $c->log->debug("Deleting key: '$key'");
    return $c->_redis_op('del', $key);
}

sub delete_expired_sessions {
    # Null op, Redis handles this for us!
}

sub setup_session {
    my ($c) = @_;

    $c->maybe::next::method(@_);
}

sub _verify_redis_connect {
    my ($c) = @_;

    my $cfg = $c->_session_plugin_config;
    croak "Config not contains 'redis_config' section" if not $cfg->{redis_config};

    my $redis_db = delete $cfg->{redis_config}->{redis_db} // 0;

    if ((not $c->_session_redis_storage) or (not $c->_session_redis_storage->ping)) {
        $c->_session_redis_storage(Redis::Fast->new(
                %{$cfg->{redis_config}},
            )
        );
        $c->_session_redis_storage->select($redis_db);
    }
}

sub _redis_op {
    #Execute Redis operation
    my ($c, $op, @args) = @_;
    my $retry_count = 10;
    while (--$retry_count > 0) {
        my $res = eval {$c->_session_redis_storage->$op(@args)};
        if ($@) {
            $c->_verify_redis_connect;
        }
        else {
            return $res;
        }
    }
    die $@;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Session::Store::RedisFast - Redis Session store for Catalyst framework

=head1 VERSION

version 0.03

=head1 SYNOPSYS

    use Catalyst qw/
        Session
        Session::Store::RedisFast
    /;

    # Use single instance of Redis
    MyApp->config->{Plugin::Session} = {
        expires             => 3600,
        redis_config        => {
            server                  => '127.0.0.1:6300',
        },
    };

    # or
    # Use Redis Sentinel
    MyApp->config->{Plugin::Session} = {
        expires             => 3600,
        redis_config        => {
            sentinels                   => [
                '192.168.136.90:26379',
                '192.168.136.91:26379',
                '192.168.136.92:26379',
            ],
            reconnect                   => 1000,
            every                       => 100_000,
            service                     => 'master01',
            sentinels_cnx_timeout       => 0.1,
            sentinels_read_timeout      => 1,
            sentinels_write_timeout     => 1,
            redis_db                    => 0,
        },
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::RedisFast> - is a session storage plugin for Catalyst that uses the Redis::Fast as Redis storage module and CBOR::XS as serializing/deserealizing prel data to string

=head2 CONFIGURATIN

=head3 redis_config

Options save as L<Redis::Fast>

=head3 expires

Default ttl time to session keys

=head1 DEPENDENCE

L<Redis::Fast>, L<CBOR::XS>, L<MIME::Base64>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

=cut

