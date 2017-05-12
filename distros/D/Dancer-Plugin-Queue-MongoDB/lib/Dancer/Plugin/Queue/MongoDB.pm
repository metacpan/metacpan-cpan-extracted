use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Queue::MongoDB;
# ABSTRACT: Dancer::Plugin::Queue backend using MongoDB
our $VERSION = '0.003'; # VERSION

# Dependencies
use Moose;
use MooseX::AttributeShortcuts;
use MongoDBx::Queue 1.000; # new API
use namespace::autoclean;

with 'Dancer::Plugin::Queue::Role::Queue';


has db_name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has queue_name => (
  is      => 'ro',
  isa     => 'Str',
  default => 'queue',
);


has connection_options => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);


has queue => (
  is         => 'lazy',
  isa        => 'MongoDBx::Queue',
);

sub _build_queue {
  my ($self) = @_;
  return MongoDBx::Queue->new(
    database_name => $self->db_name,
    collection_name => $self->queue_name,
    client_options => $self->connection_options,
  );
}

sub add_msg {
  my ( $self, $data ) = @_;
  $self->queue->add_task( { data => $data } );
}

sub get_msg {
  my ($self) = @_;
  my $msg = $self->queue->reserve_task;
  return ( $msg, $msg->{data} );
}

sub remove_msg {
  my ( $self, $msg ) = @_;
  $self->queue->remove_task($msg);
}

__PACKAGE__->meta->make_immutable;

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding utf-8

=head1 NAME

Dancer::Plugin::Queue::MongoDB - Dancer::Plugin::Queue backend using MongoDB

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # in config.yml

  plugins:
    Queue:
      default:
        class: MongoDB
        options:
          db_name: dancer_test
          queue_name: msg_queue
          connection_options:
            host: mongodb://localhost:27017

  # in Dancer app

  use Dancer::Plugin::Queue::MongoDB;

  get '/' => sub {
    queue->add_msg( $data );
  };

=head1 DESCRIPTION

This module implements a L<Dancer::Plugin::Queue> using L<MongoDBx::Queue>.

=head1 ATTRIBUTES

=head2 db_name

Name of the database to hold the queue collection. Required.

=head2 queue_name

Name of the collection that defines the queue. Defaults to 'queue'.

=head2 connection_options

MongoDB::Connection options hash to create the connection to the database
holding the queue.  Empty by default, which means connecting to localhost
on the default port.

=head2 queue

The MongoDBX::Queue object that manages the queue.  Built on demand from
other attributes.

=for Pod::Coverage add_msg get_msg remove_msg

=head1 USAGE

See documentation for L<Dancer::Plugin::Queue>.

=head1 SEE ALSO

=over 4

=item *

L<Dancer::Plugin::Queue>

=item *

L<MongoDBx::Queue>

=item *

L<MongoDB::Connection>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dancer-Plugin-Queue-MongoDB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dancer-Plugin-Queue-MongoDB>

  git clone https://github.com/dagolden/Dancer-Plugin-Queue-MongoDB.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
