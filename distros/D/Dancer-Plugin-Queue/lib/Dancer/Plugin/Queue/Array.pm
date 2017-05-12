use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Queue::Array;
# ABSTRACT: No abstract given for Dancer::Plugin::Queue::Array
our $VERSION = '0.002'; # VERSION

# Dependencies
use Moo;
with 'Dancer::Plugin::Queue::Role::Queue';


has name => (
    is       => 'ro',
    required => 1,
);

has _messages => (
    is      => 'ro',
    default => sub { [] },
);


sub add_msg {
    my ( $self, $msg ) = @_;
    push @{ $self->_messages }, $msg;
}


sub get_msg {
    my ($self) = @_;
    my $msg = shift @{ $self->_messages };
    return wantarray ? ( $msg, $msg ) : $msg;
}


sub remove_msg {
    my ( $self, $msg ) = @_;
    # XXX NOOP since 'get_msg' already removes it
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding utf-8

=head1 NAME

Dancer::Plugin::Queue::Array - No abstract given for Dancer::Plugin::Queue::Array

=head1 VERSION

version 0.002

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
