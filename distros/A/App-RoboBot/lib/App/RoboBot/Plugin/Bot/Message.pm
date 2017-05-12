package App::RoboBot::Plugin::Bot::Message;
$App::RoboBot::Plugin::Bot::Message::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 bot.message

Provides functions to access details and metadata for the current message
context.

=cut

has '+name' => (
    default => 'Bot::Message',
);

has '+description' => (
    default => 'Provides functions to access details and metadata for the current message context.',
);

=head2 msg-text

=head3 Description

=head3 Usage

=head3 Examples

=cut

has '+commands' => (
    default => sub {{
        'msg-text' => { method          => 'message_message',
                        description     => 'Returns the text of the current message context.', },

        'msg-sender' => { method      => 'message_sender',
                          description => 'Returns the name of the sender of the current message context.', },
    }},
);

sub message_message {
    my ($self, $message, $command, $rpl) = @_;

    return $message->raw;
}

sub message_sender {
    my ($self, $message, $command, $rpl) = @_;

    return $message->sender->name;
}

__PACKAGE__->meta->make_immutable;

1;
