package App::RoboBot::Plugin::Bot::Redirection;
$App::RoboBot::Plugin::Bot::Redirection::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 bot.redirection

Provides functions for modifying the recipient(s) of function output.

=cut

has '+name' => (
    default => 'Bot::Redirection',
);

has '+description' => (
    default => 'Provides functions for modifying the recipient(s) of function output.',
);

=head2 to-nick

=head3 Description

Redirects output to a private message delivered to the given nick. Must be on
the same server. All input values are passed through unchanged.

=head3 Usage

<recipient name> <value> [<value> ...]

=head3 Examples

    (to-nick dungeonmaster (join ": " "I roll stealth" (roll 20 1)))

=head2 to-channel

=head3 Description

Redirects output to a specific channel. Must be on the same server. All input
values are passed through unchanged.

=head3 Usage

<channel name> <value> [<value> ...]

=head3 Examples

    (to-channel #boringchannel "Join us over in #superfunchannel!")

=cut

has '+commands' => (
    default => sub {{
        'to-nick' => { method      => 'to_nick',
                       description => 'Redirects output to a private message delivered to the given nick. Must be on the same server. All input values are passed through unchanged.',
                       usage       => '<nick> <value> [<value 2> ... <value N>]',
                       example     => 'dungeonmaster (join ": " "I roll stealth" (roll 20 1))',
                       result      => '[dungeonmaster] I roll stealth: 18' },

        'to-channel' => { method      => 'to_channel',
                          description => 'Redirects output to a specific channel. Must be on the same server. All input values are passed through unchanged.',
                          usage       => '<channel> <value> [<value 2> ... <value N>]',
                          example     => '#boringchan "Join us over in #superfunchan!"',
                          result      => '[#boringchan] Join us over in #superfunchan!' },
    }},
);

sub to_nick {
    my ($self, $message, $command, $rpl, $to_nick, @args) = @_;

    # TODO: more protection against malicious nick input (maybe done in Nick.pm)

    my ($nick);

    if ($nick = App::RoboBot::Nick->new( config => $self->bot->config, name => "$to_nick" )) {
        $message->response->nick($nick);
        $message->response->clear_channel;
    } else {
        $message->response->raise(sprintf('Could not instantiate nick recipient: %s', $to_nick));
    }

    return @args;
}

sub to_channel {
    my ($self, $message, $command, $rpl, $to_channel, @args) = @_;

    $to_channel =~ s{^\#*}{}ogs;

    if (my $channel = (grep { lc($_->name) eq lc($to_channel) } @{$message->network->channels})[0]) {
        $message->response->channel($channel);
        $message->response->clear_nick;
    } else {
        $message->response->raise(sprintf('I do not appear to be connected to the channel #%s.', $to_channel));
    }

    return @args;
}

__PACKAGE__->meta->make_immutable;

1;
