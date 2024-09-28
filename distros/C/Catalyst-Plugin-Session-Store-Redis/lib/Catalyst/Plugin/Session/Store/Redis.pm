package Catalyst::Plugin::Session::Store::Redis;

# ABSTRACT: Redis Session store for Catalyst
our $VERSION = '0.901'; # VERSION

use warnings;
use strict;

use base qw/
    Class::Data::Inheritable
    Catalyst::Plugin::Session::Store
/;
use MRO::Compat;
use MIME::Base64 qw(encode_base64 decode_base64);
use Redis;
use Storable qw/nfreeze thaw/;
use Try::Tiny;

__PACKAGE__->mk_classdata(qw/_session_redis_storage/);

sub get_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    if(my ($sid) = $key =~ /^expires:(.*)/) {
        $c->log->debug("Getting expires key for $sid");
        return $c->_session_redis_storage->get($key);
    } else {
        $c->log->debug("Getting $key");
        my $data = $c->_session_redis_storage->get($key);
        if(defined($data)) {
            return thaw( decode_base64($data) )
        }
    }

    return;
}

sub store_session_data {
    my ($c, $key, $data) = @_;

    $c->_verify_redis_connection;

    if(my ($sid) = $key =~ /^expires:(.*)/) {
        $c->log->debug("Setting expires key for $sid: $data");
        $c->_session_redis_storage->set($key, $data);
    } else {
        $c->log->debug("Setting $key");
        $c->_session_redis_storage->set($key, encode_base64(nfreeze($data)));
    }

    # We use expire, not expireat because it's a 1.2 feature and as of this
    # release, 1.2 isn't done yet.
    my $exp = $c->session_expires;
    my $duration = $exp - time;
    $c->_session_redis_storage->expire($key, $duration);
    # $c->_session_redis_storage->expireat($key, $exp);

    return;
}

sub delete_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    $c->log->debug("Deleting: $key");
    $c->_session_redis_storage->del($key);

    return;
}

sub delete_expired_sessions {
    my ($c) = @_;

    # Null op, Redis handles this for us!
}

sub setup_session {
    my ($c) = @_;

    $c->maybe::next::method(@_);
}

sub _verify_redis_connection {
    my ($c) = @_;

    my $cfg = $c->_session_plugin_config;

    try {
        $c->_session_redis_storage->ping;
    } catch {
        $c->_session_redis_storage(
            Redis->new(
                server                 => $cfg->{redis_server}                 || '127.0.0.1:6379',
                debug                  => $cfg->{redis_debug}                  || 0,
                reconnect              => $cfg->{redis_reconnect}              || 0,
                conservative_reconnect => $cfg->{redis_conservative_reconnect} || 0,
                ssl                    => $cfg->{redis_ssl}                    || 0,
                ( ( $cfg->{redis_ssl_verify_mode} and $cfg->{redis_ssl} ) ? ( SSL_verify_mode => $cfg->{redis_ssl_verify_mode} ) : () ),
                ( $cfg->{redis_name} ? ( name => $cfg->{redis_name} ) : () ),
                ( $cfg->{redis_username} ? ( username => $cfg->{redis_username} ) : () ),
                ( $cfg->{redis_password} ? ( password => $cfg->{redis_password} ) : () ),
            )
        );
        if ($c->_session_redis_storage && $cfg->{redis_db}) {
            $c->_session_redis_storage->select($cfg->{redis_db});
        }
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Session::Store::Redis - Redis Session store for Catalyst

=head1 VERSION

version 0.901

=head1 SYNOPSIS

    use Catalyst qw/
        Session
        Session::Store::Redis
        Session::State::Foo
    /;
    
    MyApp->config->{Plugin::Session} = {
        expires => 3600,
        redis_server => '127.0.0.1:6379',
        redis_debug => 0, # or 1!
        redis_reconnect => 0, # or 1
        redis_db => 5, # or 0 by default
        redis_ssl => 1, # or 0
        redis_name => 'name',
        redis_username => 'username', # or default user
        redis_password => 'password',
        redis_ssl_verify_mode => SSL_VERIFY_PEER, # IO::Socket::SSL
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::Redis> is a session storage plugin for
Catalyst that uses the Redis (L<http://redis.io/>) key-value
database.

=head2 CONFIGURATION

=head3 redis_server

The IP address and port where your Redis is running. Default: 127.0.0.1:6379

=head3 redis_debug

Boolean flag to turn Redis debug messages on/off. Default: 0, i.e. off

Turing this on will cause the Redis Perl bindings to output debug
messages to STDOUT. This setting does not influence the logging this
module does via C<< $c->log >>

=head3 redis_reconnect

Boolean flag. Default: 0, i.e. off.

It is highly recommended that you enable this setting. If set to C<0>,
your app might not be able to reconnect to C<Redis> if the C<Redis>
server was restarted.

I leave the default of setting at C<0> for now because changing it
might break existing apps.

Do not use this setting with authentication.

=head3 redis_conservative_reconnect

Boolean flag. Default: 0, i.e. off.

Use this setting for reconnect with authentication.

=head3 redis_ssl

Boolean flag. Default: 0, i.e. off.

You can connect to Redis over SSL/TLS by setting this flag if the
target Redis server or cluster has been setup to support SSL/TLS.
This requires L<IO::Socket::SSL> to be installed on the client. It's off by default.

=head3 redis_ssl_verify_mode

This parameter will be applied when C<redis_ssl> flag is set. It sets
the verification mode for the peer certificate. It's compatible with
the parameter with the same name in L<IO::Socket::SSL>.

=head3 redis_name

Setting a different name for the connection.

=head3 redis_username

The username for the authentication

=head3 redis_password

The password, if your Redis server requires authentication.

=head1 NOTES

=over 4

=item B<Expired Sessions>

This store does B<not> automatically expires sessions.  There is no need to
call C<delete_expired_sessions> to clear any expired sessions.

domm: No idea what this means.

=item B<session expiry>

Currently this module does not use C<Redis> Expiry to clean out old
session. I might look into this in the future. But patches are welcome!

=back

=head1 AUTHORS

Cory G Watson, C<< <gphat at cpan.org> >>

=head2 Current Maintainer

Thomas Klausner C<< domm@cpan.org >>

=head2 Contributors

=over

=item * Andreas Granig L<https://github.com/agranig>

=item * Mohammad S Anwar L<https://github.com/manwar>

=item * Torsten Raudssus L<https://github.com/Getty>

=back

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
