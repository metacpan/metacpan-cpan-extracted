package Dancer::Plugin::Queue::SQS;

use strict;
use warnings;

use Amazon::SQS::Simple;

use Moo;
use namespace::autoclean;
with 'Dancer::Plugin::Queue::Role::Queue';

=head1 NAME

Dancer::Plugin::Queue::SQS - SQS Adapter for Dancer::Plugin::Queue

=head1 DESCRIPTION

This module implements a L<Dancer::Plugin::Queue> using L<Amazon::SQS::Simple>.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 ATTRIBUTES

=head2 access_key

AWS Access Key with SQS Permissions. Required.

=cut

has access_key => (
  is => 'ro',
  required => 1
);

=head2 secret_key

AWS Secret Key with SQS Permissions. Required.

=cut

has secret_key => (
  is => 'ro',
  required => 1
);

=head2 queue_name

Name of the collection that defines the queue. Defaults to 'queue'.

=cut

has queue_name => (
  is => 'ro',
  required => 1,
  default => 'queue'
);

=head2 queue

The Amazon::SQS::Simple::Queue object that holds the queue.  Built on demand from
other attributes.

=cut

has queue => (
  is => 'lazy'
);

=head2 sqs

The Amazon::SQS::Simple object that holds the sqs connection.  Built on demand from
other attributes.

=cut

has sqs => (
  is => 'lazy'
);

=for Pod::Coverage add_msg get_msg remove_msg

=head1 USAGE

See documentation for L<Dancer::Plugin::Queue>.

=head1 SEE ALSO

=over 4

=item *

L<Dancer::Plugin::Queue>

=item *

L<Amazon::SQS::Simple>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/Casao/Dancer-Plugin-Queue-SQS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/Casao/Dancer-Plugin-Queue-SQS>

  git clone https://github.com/Casao/Dancer-Plugin-Queue-SQS.git

=head1 AUTHOR

Colin Ewen <casao@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Colin Ewen

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

sub _build_queue {
  my ($self) = @_;
  return $self->sqs->CreateQueue($self->queue_name);
}

sub _build_sqs {
  my ($self) = @_;
  return new Amazon::SQS::Simple($self->access_key, $self->secret_key);
}

sub add_msg {
  my ($self, $data) = @_;
  return $self->queue->SendMessage($data);
}

sub get_msg {
  my ($self) = @_;
  my $msg = $self->queue->ReceiveMessage();
  return ( $msg, $msg->MessageBody() ) if $msg;
}

sub remove_msg {
  my ($self, $msg) = @_;
  $self->queue->DeleteMessage($msg);
}

1;
