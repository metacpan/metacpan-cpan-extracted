NAME

    Crixa - A Cleaner API for Net::AMQP::RabbitMQ

VERSION

    version 0.13

SYNOPSIS

        use Crixa;
    
        my $mq       = Crixa->connect( host => 'localhost' );
        my $channel  = $mq->new_channel;
        my $exchange = $channel->exchange( name => 'hello' );
    
        $exchange->publish('Hello World');
    
        my $queue = $exchange->queue( name => 'hello' );
    
        $queue->handle_message( sub { say $_->body } );

DESCRIPTION

        All the world will be your enemy, Prince of a Thousand enemies. And when
        they catch you, they will kill you. But first they must catch you; digger,
        listener, runner, Prince with the swift warning. Be cunning, and full of
        tricks, and your people will never be destroyed. -- Richard Adams

    This module provides a more natural API over Net::AMQP::RabbitMQ, with
    separate objects for channels, exchanges, and queues.

WARNING

    Crixa is still in development and the API may change in the future!

METHODS

    This class provides the following methods:

 Crixa->connect(...)

    Creates a new connection to a RabbitMQ server. It takes a hash or
    hashref of named parameters.

    host => $hostname

      The hostname to connect to. Required.

    port => $post

      An optional port.

    user => $user

      An optional username.

    password => $password

      An optional password.

    mq => $mq

      This is an optional parameter which can contain an object which
      implements the Net::AMQP::RabbitMQ interface.

      Normally this will be created as needed but you can pass a
      Test::Net::RabbitMQ object instead so you can write tests for code
      that uses Crixa without actually having a rabbitmq server running.

      Note that Test::Net::RabbitMQ does not (as of version 0.10) implement
      the entire Net::AMQP::RabbitMQ interface so some Crixa methods may
      blow up with Test::Net::RabbitMQ.

      See the section on "MOCKING" for more details.

 $crixa->new_channel

    Returns a new Crixa::Channel object.

    You can use the channel to create exchanges and queues.

 $crixa->disconnect

    Disconnect from the server. This is called implicitly by DEMOLISH so
    normally there should be no need to do this explicitly.

 $crixa->host

    Returns the port passed to the constructor, if nay.

 $crixa->user

    Returns the user passed to the constructor, if any.

 $crixa->password

    Returns the password passed to the constructor, if any.

 $crixa->is_connected

    This returns true if the underlying mq object thinks it is connected.

MOCKING

    If you are testing code that uses Crixa, you may want to mock out the
    use of an actual rabbitmq server with something that is a little
    simpler to test. In that case, you can pass a Test::Net::RabbitMQ
    object to the Crixa->connect method:

        my $test_mq = Test::Net::RabbitMQ->new;
        my $crixa   = Crixa->connect(
            host => 'irrelevant',
            mq   => $test_mq,
        );

    Note that if you are publishing and consuming messages, this all must
    happen in a single process and a single Test::Net::RabbitMQ object in
    order for this mocking to work.

    If the code that publishes messages makes a separate Crixa object from
    the one you use to test those messages, you need to be careful to share
    the same Test::Net::RabbitMQ object. Also, since the Crixa object calls
    its disconnect() method when it goes out of scope, you may need to
    reconnect the Test::Net::RabbitMQ object or it will die when you call
    methods on it.

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

    We can fix this by adding an extra "safety" call to connect the
    $test_mq object in the test_messages() sub:

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

    Of course, this is a very artificial example, but in real code you may
    come across this problem.

SUPPORT

    Please report all issues with this code using the GitHub issue tracker
    at https://github.com/Tamarou/Crixa/issues.

SEE ALSO

    This module uses Net::AMQP::RabbitMQ under the hood, though it does not
    expose everything provided by its API.

    The best documentation we've found on RabbitMQ (and AMQP) concepts is
    the Bunny documentation at http://rubybunny.info/articles/guides.html.
    We strongly recommend browsing this to get a better understanding of
    how RabbitMQ works, what different options for exchanges, queues, and
    messages mean, and more.

AUTHORS

      * Chris Prather <chris@prather.org>

      * Dave Rolsky <autarch@urth.org>

CONTRIBUTORS

      * Gregory Oschwald <goschwald@maxmind.com>

      * Gregory Oschwald <oschwald@gmail.com>

      * Ran Eilam <ran.eilam@gmail.com>

      * Torsten Raudssus <torsten@raudss.us>

COPYRIGHT AND LICENSE

    This software is copyright (c) 2012 - 2015 by Chris Prather.

    This is free software; you can redistribute it and/or modify it under
    the same terms as the Perl 5 programming language system itself.

