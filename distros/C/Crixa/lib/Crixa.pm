package Crixa;

use v5.10;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.13';

use Moose;

use Crixa::Channel;
use Net::AMQP::RabbitMQ 0.310000;

with qw(Crixa::HasMQ);

has '+_mq' => (
    init_arg => 'mq',
    required => 0,
    lazy     => 1,
    builder  => '_build_mq',
    handles  => [qw( disconnect )],
);

has host => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has [qw(user password)] => (
    isa => 'Str',
    is  => 'ro',
);

has port => (
    isa => 'Int',
    is  => 'ro',
);

has _channel_id => (
    isa     => 'Int',
    default => 0,
    traits  => ['Counter'],
    handles => {
        _next_channel_id   => 'inc',
        release_channel_id => 'dec',
        reset_channel_id   => 'reset',
    },
);

sub _build_mq { Net::AMQP::RabbitMQ->new; }

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub connect {
    my $self = shift->new(@_);
    $self->_connect_mq($self);
    return $self;
}
## use critic

sub _connect_mq {
    my ( $self, $crixa ) = @_;

    my %args;
    for (qw( user password port )) {
        $args{$_} = $crixa->$_ if defined $crixa->$_;
    }
    $self->_mq->connect( $crixa->host, \%args );
}

sub new_channel {
    my $self = shift;

    return Crixa::Channel->new(
        id  => $self->_next_channel_id,
        _mq => $self->_mq,
    );
}

sub is_connected {
    my $self = shift;

    return
          $self->_mq->can('is_connected') ? $self->_mq->is_connected
        : $self->_mq->can('connected')    ? $self->_mq->connected
        : die
        'The underlying mq object does not have an is_connected or connected method!';
}

sub DEMOLISH {
    my $self = shift;
    $self->disconnect if $self->_mq && $self->is_connected;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A Cleaner API for Net::AMQP::RabbitMQ

__END__

=pod

=head1 NAME

Crixa - A Cleaner API for Net::AMQP::RabbitMQ

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use Crixa;

    my $mq       = Crixa->connect( host => 'localhost' );
    my $channel  = $mq->new_channel;
    my $exchange = $channel->exchange( name => 'hello' );

    $exchange->publish('Hello World');

    my $queue = $exchange->queue( name => 'hello' );

    $queue->handle_message( sub { say $_->body } );

=head1 DESCRIPTION

    All the world will be your enemy, Prince of a Thousand enemies. And when
    they catch you, they will kill you. But first they must catch you; digger,
    listener, runner, Prince with the swift warning. Be cunning, and full of
    tricks, and your people will never be destroyed. -- Richard Adams

This module provides a more natural API over L<Net::AMQP::RabbitMQ>, with
separate objects for channels, exchanges, and queues.

=encoding UTF-8

=head1 WARNING

B<Crixa is still in development and the API may change in the future!>

=head1 METHODS

This class provides the following methods:

=head2 Crixa->connect(...)

Creates a new connection to a RabbitMQ server. It takes a hash or hashref of
named parameters.

=over 4

=item host => $hostname

The hostname to connect to. Required.

=item port => $post

An optional port.

=item user => $user

An optional username.

=item password => $password

An optional password.

=item mq => $mq

This is an optional parameter which can contain an object which implements the
C<Net::AMQP::RabbitMQ> interface.

Normally this will be created as needed but you can pass a
L<Test::Net::RabbitMQ> object instead so you can write tests for code that
uses Crixa without actually having a rabbitmq server running.

Note that L<Test::Net::RabbitMQ> does not (as of version 0.10) implement the
entire L<Net::AMQP::RabbitMQ> interface so some Crixa methods may blow up with
L<Test::Net::RabbitMQ>.

See the section on L</MOCKING> for more details.

=back

=head2 $crixa->new_channel

Returns a new L<Crixa::Channel> object.

You can use the channel to create exchanges and queues.

=head2 $crixa->disconnect

Disconnect from the server. This is called implicitly by C<DEMOLISH> so
normally there should be no need to do this explicitly.

=head2 $crixa->host

Returns the port passed to the constructor, if nay.

=head2 $crixa->user

Returns the user passed to the constructor, if any.

=head2 $crixa->password

Returns the password passed to the constructor, if any.

=head2 $crixa->is_connected

This returns true if the underlying mq object thinks it is connected.

=head1 MOCKING

If you are testing code that uses Crixa, you may want to mock out the use of
an actual rabbitmq server with something that is a little simpler to test. In
that case, you can pass a L<Test::Net::RabbitMQ> object to the C<<
Crixa->connect >> method:

    my $test_mq = Test::Net::RabbitMQ->new;
    my $crixa   = Crixa->connect(
        host => 'irrelevant',
        mq   => $test_mq,
    );

Note that if you are publishing and consuming messages, this all must happen
in a single process B<and a single L<Test::Net::RabbitMQ> object> in order for
this mocking to work.

If the code that publishes messages makes a separate Crixa object from the one
you use to test those messages, you need to be careful to share the same
L<Test::Net::RabbitMQ> object. Also, since the Crixa object calls its
C<disconnect()> method when it goes out of scope, you may need to reconnect
the L<Test::Net::RabbitMQ> object or it will die when you call methods on it.

Here's an example:

    my $test_mq = Test::Net::RabbitMQ->new;
    test_messages($test_mq) :;

    sub test_messages {
        my $mq    = shift;
        my $crixa = Crixa->connect(
            host => 'irrelevant',
            mq   => $test_mq,
        );

        publish($test_mq);

        # This will die!
        my @messages = $crixa->channel->queue(...)->check_for_messages;
    }

    sub publish {
        my $mq    = shift;
        my $crixa = Crixa->connect(
            host => 'irrelevant',
            mq   => $test_mq,
        );

        # publish some messages

        # When the sub exits the $crixa object calls disconnect() on itself.
    }

We can fix this by adding an extra "safety" call to connect the C<$test_mq>
object in the C<test_messages()> sub:

    sub test_messages {
        my $mq    = shift;
        my $crixa = Crixa->connect(
            host => 'irrelevant',
            mq   => $test_mq,
        );

        publish($test_mq);

        $test_mq->connect unless $test_mq->connected;

        # This will die!
        my @messages = $crixa->channel->queue(...)->check_for_messages;
    }

Of course, this is a very artificial example, but in real code you may come
across this problem.

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/Tamarou/Crixa/issues>.

=head1 SEE ALSO

This module uses L<Net::AMQP::RabbitMQ> under the hood, though it does not
expose everything provided by its API.

The best documentation we've found on RabbitMQ (and AMQP) concepts is the
Bunny documentation at http://rubybunny.info/articles/guides.html. We strongly
recommend browsing this to get a better understanding of how RabbitMQ works,
what different options for exchanges, queues, and messages mean, and more.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTORS

=for stopwords Gregory Oschwald Ran Eilam Torsten Raudssus

=over 4

=item *

Gregory Oschwald <goschwald@maxmind.com>

=item *

Gregory Oschwald <oschwald@gmail.com>

=item *

Ran Eilam <ran.eilam@gmail.com>

=item *

Torsten Raudssus <torsten@raudss.us>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2015 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
