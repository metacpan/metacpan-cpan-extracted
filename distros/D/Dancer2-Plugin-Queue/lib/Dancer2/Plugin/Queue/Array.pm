use 5.008001;
use strict;
use warnings;

package Dancer2::Plugin::Queue::Array;
# ABSTRACT: Single-process, in-memory queue

our $VERSION = '0.006';

# Dependencies
use Moo;
use MooX::Types::MooseLike::Base qw/Str ArrayRef/;
with 'Dancer2::Plugin::Queue::Role::Queue';

#pod =attr name
#pod
#pod The C<name> attribute does nothing useful, but it's required
#pod in order to test how options are passed to queue implementations
#pod
#pod =cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _messages => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

#pod =method add_msg
#pod
#pod   $queue->add_msg( $data );
#pod
#pod Enqueues $data as a message.
#pod
#pod =cut

sub add_msg {
    my ( $self, $msg ) = @_;
    push @{ $self->_messages }, $msg;
}

#pod =method get_msg
#pod
#pod   my ($msg, $data) = $queue->get_msg;
#pod
#pod Dequeues a message.
#pod
#pod =cut

sub get_msg {
    my ($self) = @_;
    my $msg = shift @{ $self->_messages };
    return wantarray ? ( $msg, $msg ) : $msg;
}

#pod =method remove_msg
#pod
#pod   $queue->remove_msg( $msg );
#pod
#pod Usually would remove a message from the queue as deleted, but
#pod for this demo class, does nothing, since C<get_msg> already removed it.
#pod
#pod =cut

sub remove_msg {
    my ( $self, $msg ) = @_;
    # XXX NOOP since 'get_msg' already removes it
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Queue::Array - Single-process, in-memory queue

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  # in dancer config.yml
  
  queue:
    default:
      class: Array
      options:
        name: test

=head1 DESCRIPTION

This module provides a trivial, single-process, in-memory queue
for testing.

=head1 ATTRIBUTES

=head2 name

The C<name> attribute does nothing useful, but it's required
in order to test how options are passed to queue implementations

=head1 METHODS

=head2 add_msg

  $queue->add_msg( $data );

Enqueues $data as a message.

=head2 get_msg

  my ($msg, $data) = $queue->get_msg;

Dequeues a message.

=head2 remove_msg

  $queue->remove_msg( $msg );

Usually would remove a message from the queue as deleted, but
for this demo class, does nothing, since C<get_msg> already removed it.

=for Pod::Coverage method_names_here

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
