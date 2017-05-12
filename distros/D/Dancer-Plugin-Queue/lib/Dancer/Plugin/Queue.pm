use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Queue;
# ABSTRACT: Dancer plugin for message queue abstractions
our $VERSION = '0.002'; # VERSION

use Dancer::Plugin;
use Class::Load qw/try_load_class/;

my %queues;
my $conf;

register queue => sub {
    my ( $self, $name ) = plugin_args(@_);
    $conf ||= plugin_setting();

    # if name not specified, DWIM or use 'default'
    if ( not defined $name ) {
        if ( keys %$conf == 1 ) {
            ($name) = keys %$conf;
        }
        elsif ( exists $conf->{default} ) {
            $name = "default";
        }
        else {
            die "Can't determine a default queue name";
        }
    }

    # return cached object if already created
    return $queues{$name} if defined $queues{$name};

    # otherwise, instantiate the object from config settings
    my $queue_conf = $conf->{$name}
      or die "No configuration for queue '$name'";

    my $class = $queue_conf->{class}
      or die "No class specified for queue '$name'";

    $class = "Dancer::Plugin::Queue::$class";

    try_load_class($class)
      or die "Queue class '$class' could not be loaded";

    $class->can('DOES') && $class->DOES("Dancer::Plugin::Queue::Role::Queue")
      or die "Queue class '$class' does not implement the expected role";

    my $object = eval { $class->new( $queue_conf->{options} || {} ) }
      or die "Could not create $class object: $@";

    return $queues{$name} = $object;
};

register_plugin;
1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding utf-8

=head1 NAME

Dancer::Plugin::Queue - Dancer plugin for message queue abstractions

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # in config.yml

  plugins:
    Queue:
      default:
        class: Array
        options:
          name: not_a_real_queue

  # in your app

  use Dancer::Plugin::Queue;

  post '/add_fortune' => sub {
    # assume a 'fortune' parameter submitted
    queue->add_msg( params->{fortune} );
    # ...
  };

  get '/tell_fortune' => sub {
    my ($msg, $body) = queue->get_msg;
    queue->remove_msg( $msg );
    return "Your fortune: $body";
  };

=head1 DESCRIPTION

This module provides a generic interface to a message queue.  Message queue
implementations must implement the L<Dancer::Plugin::Queue::Role::Queue> role,
which defines the interface to abstract the specifics of the backend.

=for Pod::Coverage method_names_here

=head1 CONFIGURATION

Queue objects are defined by a C<< NAME => HASHREF >> pair.  The hash reference
must contain a 'class' key, whose value is a class name suffix that will be
appended to C<Dancer::Plugin::Queue::>.  The resulting class will be loaded on
demand.  If the hash reference contains an 'options' key, its value will be
passed to the constructor when the queue object is created.

=head1 USAGE

=head2 queue

  queue;
  queue($name);

This function returns a C<Dancer::Plugin::Queue::*> object.  If no C<$name> is
provided, it attempts to return a default object.  If there is only a single
queue defined, it will be used as the default.  If there is more than one, a
queue called 'default' will be the default.  If there are more than one and
none are named 'default', an error will be thrown.

=head2 queue->add_msg

  queue->add_msg( $data );

Adds C<$data> to the queue.  It is up to the plugin implementation (or backend)
to serialize or otherwise modify C<$data>.

=head2 queue->get_msg

  ( $msg, $data ) = queue->get_msg;

Dequeues a message from the queue.  C<$msg> will be either a 'raw' message object
from the backend or else an identifier that can be used with C<remove_msg>.
C<$data> should ideally be the same as the enqueued C<$data>, subject to any
round-trip limitations of the backend.

=head2 queue->remove_msg

  queue->remove_msg( $msg );

Removes a message permanently from the queue (if not already done by C<get_msg>).

Some message queue implementations require handled messages to be manually
removed from the queue or else the message will time-out and be available
again.

This method should always be called after a message has been handled in case
the backend requires such cleanup.  For implementations that do not have
message durability, this method may do nothing.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dancer-Plugin-Queue/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dancer-Plugin-Queue>

  git clone https://github.com/dagolden/Dancer-Plugin-Queue.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
