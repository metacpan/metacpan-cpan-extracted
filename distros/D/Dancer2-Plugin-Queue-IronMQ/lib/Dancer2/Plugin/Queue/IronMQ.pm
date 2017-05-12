## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (ControlStructures::ProhibitPostfixControls)
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

package Dancer2::Plugin::Queue::IronMQ;
use strict;
use warnings;
use 5.008001;

# ABSTRACT: Dancer2::Plugin::Queue backend using IronMQ
our $VERSION = '0.002'; # VERSION:

#pod =pod
#pod
#pod =encoding utf8
#pod
#pod =for stopwords IronMQ JSON config
#pod
#pod =cut

# Dependencies
use Moose;

use IO::Iron::IronMQ::Client 0.12;
use IO::Iron::IronMQ::Queue 0.12;
use IO::Iron::IronMQ::Message 0.12;

use Const::Fast;
const my $RANDOM_STRING_LENGTH => 12;

with 'Dancer2::Plugin::Queue::Role::Queue';

#pod =attr config
#pod
#pod IronMQ uses a JSON config file to hold the project_id and token,
#pod and other config items if necessary. By default F<iron.json>.
#pod These config items can also be written individually under I<connection_options>.
#pod Must be supplied.
#pod
#pod =cut

has config => (
  is      => 'ro',
  isa     => 'Str',
  default => 'iron.json',
);

#pod =attr queue
#pod
#pod Name of the queue. Must be supplied.
#pod
#pod =cut

has queue => (
  is      => 'ro',
  isa     => 'Str',
  required => 1,
);

#pod =attr timeout
#pod
#pod After timeout (in seconds), item will be placed back onto queue.
#pod You must delete the message from the queue to ensure it does not
#pod go back onto the queue. If not set, value from queue is used.
#pod Default is 60 seconds, minimum is 30 seconds,
#pod and maximum is 86,400 seconds (24 hours).
#pod
#pod =cut

has timeout => (
  is      => 'ro',
  isa     => 'Str',
  default => '60',
);

#pod =attr wait
#pod
#pod Time to long poll for messages, in seconds. Max is 30 seconds. Default 0.
#pod
#pod =cut

has wait => (
  is      => 'ro',
  isa     => 'Str',
  default => '0',
);

#The IO::Iron::IronMQ::Queue object that manages the ironmq_queue.  Built on demand from
#other attributes.
has _ironmq_queue => (
  is         => 'ro',
  isa        => 'IO::Iron::IronMQ::Queue',
  lazy_build => 1,
);

sub _build__ironmq_queue {
  my ($self) = @_;
  return $self->_ironmq_client->create_and_get_queue(
    'name' => $self->queue );
}

has _ironmq_client => (
  is         => 'ro',
  isa        => 'IO::Iron::IronMQ::Client',
  lazy_build => 1,
);

sub _build__ironmq_client {
  my ($self) = @_;
  return IO::Iron::IronMQ::Client->new( 'config' => $self->config );
}

sub add_msg {
  my ( $self, $data ) = @_;
  my $msg = IO::Iron::IronMQ::Message->new( 'body' => $data );
  $self->_ironmq_queue->post_messages( 'messages' => [ $msg ] );
  return;
}

sub get_msg {
  my ($self) = @_;
  my %options;
  $options{'timeout'} = $self->timeout if defined $self->timeout;
  $options{'wait'}    = $self->wait    if defined $self->wait;
  my ($msg) = $self->_ironmq_queue->reserve_messages( 'n' => 1, %options );
  return ( $msg, $msg->body() );
}

sub remove_msg {
  my ( $self, $msg ) = @_;
  $self->_ironmq_queue->delete_message( 'message' => $msg );
  return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Queue::IronMQ - Dancer2::Plugin::Queue backend using IronMQ

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # in config.yml

  plugins:
    Queue:
      default:
        class: IronMQ
        options:
          config: <iron json cfg file>
          queue: <queue-name>
          timeout: <seconds>
          wait: <seconds>

  # in Dancer2 app

  use Dancer2::Plugin::Queue;

  get '/' => sub {
    queue->add_msg( $data );
  };

=head1 DESCRIPTION

This module implements a L<Dancer2::Plugin::Queue|Dancer2::Plugin::Queue>
using L<IO::Iron::IronMQ::Client|IO::Iron::IronMQ::Client>.

=head1 USAGE

See documentation for L<Dancer2::Plugin::Queue|Dancer2::Plugin::Queue>.

=head1 ATTRIBUTES

=head2 config

IronMQ uses a JSON config file to hold the project_id and token,
and other config items if necessary. By default F<iron.json>.
These config items can also be written individually under I<connection_options>.
Must be supplied.

=head2 queue

Name of the queue. Must be supplied.

=head2 timeout

After timeout (in seconds), item will be placed back onto queue.
You must delete the message from the queue to ensure it does not
go back onto the queue. If not set, value from queue is used.
Default is 60 seconds, minimum is 30 seconds,
and maximum is 86,400 seconds (24 hours).

=head2 wait

Time to long poll for messages, in seconds. Max is 30 seconds. Default 0.

=for stopwords IronMQ JSON config

=for Pod::Coverage add_msg get_msg remove_msg

=head1 NOTES

My thanks to L<https://metacpan.org/author/DAGOLDEN|David Golden> who's
L<Dancer2::Plugin::Queue::MongoDB|Dancer2::Plugin::Queue::MongoDB> I used
as an example when building.

=head1 SEE ALSO

=over 4

=item *

L<Dancer2::Plugin::Queue|Dancer2::Plugin::Queue>

=item *

L<IO::Iron|IO::Iron>

=item *

L<IO::Iron::Applications|IO::Iron::Applications>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mikkoi/dancer2-plugin-queue-ironmq/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mikkoi/dancer2-plugin-queue-ironmq>

  git clone https://github.com/mikkoi/dancer2-plugin-queue-ironmq.git

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Mikko Johannes Koivunalho

Mikko Johannes Koivunalho <mikko.koivunalho@iki.fi>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mikko Koivunalho.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: ts=2 sts=2 sw=2 et:

