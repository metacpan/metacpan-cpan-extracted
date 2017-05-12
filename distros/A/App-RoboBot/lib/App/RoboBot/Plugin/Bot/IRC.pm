package App::RoboBot::Plugin::Bot::IRC;
$App::RoboBot::Plugin::Bot::IRC::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 bot.irc

Provides functions for interacting with IRC networks and channels.

=cut

has '+name' => (
    default => 'Bot::IRC',
);

has '+description' => (
    default => 'Provides functions for interacting with IRC networks and channels.',
);

=head2 irc-mode

=head3 Description

=head3 Usage

<modes> <target>

=head2 irc-kick

=head3 Description

Kicks the named user from the current channel, with the optional message. The
nick under which the bot is running must be a channel operator, or otherwise
have kick privileges for the function to do anything.

=head3 Usage

<nick> [<message>]

=cut

has '+commands' => (
    default => sub {{
        'irc-kick' => { method => 'irc_kick',
                        description => 'Kicks the named user from the current channel, with the optional message.' },
    }},
);

sub irc_kick {
    my ($self, $message, $command, $rpl, $nick, @args) = @_;

    unless ($message->response->network->type eq 'irc') {
        $self->log->error('Cannot use irc-kick on non-IRC networks.');
        $message->response->raise('irc-kick works only on IRC networks.');
        return;
    }

    unless (defined $nick && $nick =~ m{\w+}) {
        $self->log->error('No nick provided for kicking.');
        $message->response->raise('Must supply the nick to kick.');
        return;
    }

    my $msg = 'Get out.';
    $msg = join(' ', @args) if @args > 0;

    $message->response->network->kick($message->response, $nick, $msg);
    return;
}

__PACKAGE__->meta->make_immutable;

1;
