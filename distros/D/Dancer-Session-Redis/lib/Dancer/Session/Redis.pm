package Dancer::Session::Redis;

# ABSTRACT: Redis backend for Dancer Session Engine

use strict;
use warnings;
use parent 'Dancer::Session::Abstract';
use Redis 1.955;
use Dancer::Config 'setting';
use Storable ();
use Carp ();

our $VERSION = '0.22'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

my $_redis;
my %options = ();

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    # backend settings
    if (my $opts = setting('redis_session') ) {
        if (ref $opts and ref $opts eq 'HASH' ) {
            %options = (
                server   => $opts->{server}   || undef,
                sock     => $opts->{sock}     || undef,
                database => $opts->{database} || 0,
                expire   => $opts->{expire}   || 900,
                debug    => $opts->{debug}    || 0,
                password => $opts->{password} || undef,
            );
        }
        else {
            Carp::croak 'Settings redis_session must be a hash reference!';
        }
    }
    else {
        Carp::croak 'Settings redis_session is not defined!';
    }

    unless (defined $options{server} || defined $options{sock}) {
        Carp::croak 'Settings redis_session should include either server or sock parameter!';
    }

    # get radis handle
    $self->redis;
}

# create a new session
sub create {
    my ($class) = @_;

    $class->new->flush;
}

# fetch the session object by id
sub retrieve($$) {
    my ($class, $id) = @_;

    my $self = $class->new;
    $self->redis->select($options{database});
    $self->redis->expire($id => $options{expire});

    Storable::thaw($self->redis->get($id));
}

# delete session
sub destroy {
    my ($self) = @_;

    $self->redis->select($options{database});
    $self->redis->del($self->id);
}

# flush session
sub flush {
    my ($self) = @_;

    $self->redis->select($options{database});
    $self->redis->set($self->id => Storable::freeze($self));
    $self->redis->expire($self->id => $options{expire});

    $self;
}

# get redis handle
sub redis {
    my ($self) = @_;

    if (!$_redis || !$_redis->ping) {
        my %params = (
            debug     => $options{debug},
            reconnect => 10,
            every     => 100,
        );

        if (defined $options{sock}) {
            $params{sock} = $options{sock};
        }
        else {
            $params{server} = $options{server};
        }

        $params{password} = $options{password} if $options{password};

        $_redis = Redis->new(%params);
    }

    $_redis and return $_redis;

    Carp::croak "Unable connect to redis-server...";
}

1; # End of Dancer::Session::Redis

__END__

=pod

=head1 NAME

Dancer::Session::Redis - Redis backend for Dancer Session Engine

=head1 VERSION

version 0.22

=head1 SYNOPSIS

    # in the Dancer config.yml:
    session: 'Redis'
    redis_session:
        sock: '/var/run/redis.sock'
        password: 'QmG_kZECJAvAcDaWqqSqoNLUka5v3unMe_8sqYMh6ST'
        database: 1
        expire: 3600
        debug: 0

    # or in the Dancer application:
    setting redis_session => {
        server   => 'redi.example.com:6379',
        password => 'QmG_kZECJAvAcDaWqqSqoNLUka5v3unMe_8sqYMh6ST',
        database => 1,
        expire   => 3600,
        debug    => 0,
    };
    setting session => 'Redis';

=head1 DESCRIPTION

This module is a Redis backend for the session engine of Dancer application. This module is a descendant
of L<Dancer::Session::Abstract>. A simple demo apllication might be found in the C<eg/> directory of this
distribution.

=head1 CONFIGURATION

In order to use this session engine, you have to set up a few settings (in the app or app's configuration file).

=head2 session

Set the vaue B<Redis>. Required parameter.

=head2 redis_session

Settings for backend.

=head3 server

Hostname and port of the redis-server instance which will be used to store session data. This one is B<required> unless I<sock> is defined.

=head3 sock

unix socket path of the redis-server instance which will be used to store session data.

=head3 password

Password string for redis-server's AUTH command to processing any other commands. Optional. Check the redis-server
manual for directive I<requirepass> if you would to use redis internal authentication.

=head3 database

Database # to store session data. Optional. Default value is 0.

=head3 expire

Session TTL. Optional. Default value is 900 (seconds).

=head3 debug

Enables debug information to STDERR, including all interactions with the redis-server. Optional. Default value is 0.

=head1 METHODS

=head2 init

Validate settings and creates the initial connection to redis-server.

=head2 redis

Returns connection handle to the redis instance. Also establish new connection in case of C<dead> handle.

=head2 create

Creates a new object, runs C<flush> and returns the object.

=head2 flush

Writes the session information to the Redis database.

=head2 retrieve

Retrieves session information from the Redis database.

=head2 destroy

Deletes session information from the Redis database.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Dancer-Session-Redis/issues>

=head1 SEE ALSO

L<Dancer>

L<Dancer::Session>

L<Storable>

L<Redis>

L<redis.io|http://redis.io>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
