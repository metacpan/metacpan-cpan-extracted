use strict;
use warnings;

package Bot::Net::Mixin::Bot::IRC;

use Bot::Net::Mixin;

use POE qw/ Component::IRC::State /;
use Scalar::Util qw/ reftype /;

=head1 NAME

Bot::Net::Mixin::Bot::IRC - mixin class for building IRC bots

=head1 SYNOPSIS

  # Build an Eliza chatbot for IRC
  use strict;
  use warnings;
  package MyBotNet::Bot::Eliza;

  use Bot::Net::Bot;
  use Bot::Net::Mixin::Bot::IRC;
  use Chatbot::Eliza; # available separately on CPAN

  on bot startup => run {
      remember eliza => Chatbot::Eliza->new;
  };

  on bot message_to_me => run {
      my $event = get ARG0;

      my $reply = recall('eliza')->transform( $event->message );
      yield reply_to_sender => $message, $reply;
  };

  1;

=head1 DESCRIPTION

This is the mixin-class for L<Bot::Net> IRC bots. You "inherit" all the features of this mixin by using the class:

  use Bot::Net::Bot;             # define a Bot::Net bot
  use Bot::Net::Mixin::Bot::IRC; # become an IRC bot

=head1 METHODS

=head2 setup

Adds the IRC component to the bot's memory on setup. 

=cut

sub setup {
    my $self  = shift;
    my $brain = shift;

    $brain->remember(
        [ 'irc' ] => POE::Component::IRC::State->spawn( alias => 'irc' )
    );
}

=head2 default_configuration PACKAGE

Returns a base configuration for an IRC bot.

=cut

sub default_configuration {
    my $class   = shift;
    my $package = shift;

    my $name = Bot::Net->short_name_for_bot($package);
    $name =~ s/\W+/_/g;

    my $default_channel = Bot::Net->config->net('ApplicationName');
    $default_channel =~ s/\W+/_/g;

    return {
        auto_connect => 1,

        irc_connect => {
            nick     => $name,
            username => lc $name,
            ircname  => Bot::Net->short_name_for_bot($package),

            server   => 'localhost',
            port     => 6667,

            flood    => 1,
        },
        
        channels => [ '#'.$default_channel ],
    };
}

=head1 BOT STATES

The following states are avaiable for your bot to implement.

=head2 on bot connect

This is automatically yielded by L</on _start> unless the C<auto_connect> configuration option is set to "0". If it is set to "0", you may emit this state to cause the bot to connect to the IRC server.

=head2 on bot connected

This state is emitted as soon as the bot has connected to the server and the server has passed back a message. This means it is now safe to communicate with the server.

=head2 on bot message_to_group EVENT

This state occurs when the bot observes a message sent to a channel it is in, but the message is not directed at the bot (i.e., is not prefixed with "MyNick:").

The C<EVENT> is a L<Bot::Net::Message> object setup to contain the group message.

=head2 on bot message_to_me EVENT

This state occurs when either the bot observes a message sent to a channel that it is in that has been prefixed with "MyNick:" or a private message was sent directly to the bot.

The C<EVENT> is a L<Bot::Net::Message> object setup for either a group or private message depending on which occurred. If a pblic message the "MyNick:" part of the message will have been stripped.

=head1 MIXIN STATES

=head2 on _start

Sets up the IRC client.

=cut

on _start => run {
    post irc => register => 'all';

    my $auto_connect = recall [ config => 'auto_connect' ];
    if (not defined $auto_connect or $auto_connect) {
        yield 'bot_connect';
    }
};

=head2 on bot connect

Tells the IRC component to connect to the IRC server using the configuration stored in the C<irc_connect> option of the configuration.

=cut

on bot_connect => run {
    my $config = recall [ config => 'irc_connect' ] ;
    call irc => connect  => $config;
};

=head2 on irc_001

Connects to the channels that the bot has been configured to join. This then fires the L</on bot connected> event which indicates that it is now safe to issue IRC commands, if your bot needs to do so.

=cut

on irc_001 => run {
    my $self = get OBJECT;
    my $log  = recall 'log';

    my $channels = recall [ config => 'channels' ];
    for my $channel (@$channels) {
        $log->info("Joining $channel...");
        post irc => join => $channel;
    }

    yield 'bot_connected';

    # Report readiness (helpful for testing)
    my $config = recall [ config => 'irc_connect' ] ;
    recall('log')->info(
        "BOT READY : nick $config->{nick} server $config->{server} "
       ."port $config->{port}");
};

=head2 on irc_disconnected

=head2 on irc_error

=head2 on irc_socketerr

Handles bot disconnections. If the bot becomes disconnected it will automatically attempt to reconnect until the server returns or lets the bot back. It will attempt to do so in a way that will not cause it to be blocked for flooding.

=cut

on [ qw( irc_disconnected irc_error irc_socketerr ) ] => run {
    # TODO XXX FIXME Add support for notifying the bot that the connection has
    # been lost and then notifying the bot again when the connection is
    # re-established.

    delay attempt_reconnect => 60;
};

=head2 on attempt_reconnect

This state is invoked by L</on irc_disconnected> and related states. This tells the IRC client to attempt ot reconnect. This will be called repeatedly (on a delay) until a connection is reestablished.

=cut

on attempt_reconnect => run {
    post irc => 'connect';
};

=head2 irc_msg USERHOST, ME, MESSAGE

Handles IRC messages sent directly to the bot. This emits:

=over

=item bot message_to_me

See L</bot message_to_me>.

=back

=cut

on irc_msg => run {
    my $userhost = get ARG0;
    my $me       = get ARG1;
    my $message  = get ARG2;

    my ($nick, $host) = split /!/, $userhost;

    my $event = Bot::Net::Message->new({
        sender_nick     => $nick,
        sender_host     => $host,
        recipient_nicks => $me,
        message         => $message,
        private         => 1,
    });

    yield bot_message_to_me => $event;
};

=head2 irc_public USERHOST, CHANNEL, MESSAGE

Handles IRC messages sent to a public channel. This then emits additional bot states:

=over

=item bot message_to_group

Reports that a message was sent to a channel the bot is in. See L</bot message_to_group>.

=item bot message_to_me

Reports that a messages was sent to me publically in a channel. See L</bot message_to_me>.

=back

=cut

on irc_public => run {
    my $userhost = get ARG0;
    my $channel  = get ARG1;
    my $message  = get ARG2;

    my $my_nick = recall [ config => irc_connect => 'nick' ];

    my $state;
    if ($message =~ s/^\Q$my_nick\E:\s*//) {
        $state = 'message_to_me';
    }

    else {
        $state = 'message_to_group';
    }

    my ($nick, $host) = split /!/, $userhost;

    my $event = Bot::Net::Message->new({
        sender_nick      => $nick,
        sender_host      => $host,
        recipient_groups => $channel,
        message          => $message,
        public           => 1,
    });

    yield 'bot_' . $state => $event;
};

=head2 send_to DESTINATION, MESSAGE

This sends the given C<MESSAGE> to the given C<DESTINATION>. 

The C<DESTINATION> may be one of the following:

=over

=item C<#channel>

The name of a channel to send to. In this case, no special modifications will be made to the message.

=item C<nick>

The name of a nick to send to. In this case, no special modifications will be made to the message.

=item C<< [ #channel1, #channel2, nick1, nick2 ] >>

A list of channels and nicks to send to. In this case, no special modifications will be made to the message.

=item C<< { #channel1 => nick1, #channel2 => [ nick1, nick2 ] } >>

A hash of channels pointing to nicks. The nicks may be either a single nick or an array of nicks. In this case, the messages will have the given nick  (or nicks) prepended to every message sent (except continuations).

=back

If C<MESSAGE> contains new lines (\n), then the message will be broken up and sent in pieces. 

If any message that would be sent to the server approaches the 512 byte limit on IRC messages, the line will be broken. The broken line will have a backslash (\) appended at the break point of the message to signal the recipient that the line was broken. A line may be broken multiple times.

=cut

on send_to => run {
    my $to           = get ARG0;
    my $full_message = get ARG1;

    my $log     = recall 'log';

    # Split the message up by newlines
    my @messages = split /\n/, $full_message;

    # Normalize the destination by channels and nicks
    my (%group_destinations, %private_destinations);

    # Given a single channel or nick
    if (!defined reftype $to) {

        # Given a single channel
        if ($to =~ /\#/) {
            $group_destinations{$to} = [ ];
        }

        # Given a single nick
        else {
            $private_destinations{$to}++;
        }
    }

    # Given an array of channels and/or nicks
    elsif (reftype($to) eq 'ARRAY') {

        # For each channel/nick in the array...
        for my $thing (@$to) {

            # Add channels to the group list
            if ($thing =~ /\#/) {
                $group_destinations{$thing} = [ ];
            }

            # Add nicks to the private list
            else {
                $private_destinations{$thing}++;
            }
        }
    }

    # Given a hash of channels => nicks
    elsif (reftype($to) eq 'HASH') {

        # For each channel in the hash...
        for my $channel (keys %$to) {
            my $nicks = $to->{$channel};

            # If a single nick, wrap it in an array
            if (!defined reftype($nicks)) {
                $group_destinations{$channel} = [ $nicks ];
            }

            # If an array, assume an array of nicks
            elsif (reftype($nicks) eq 'ARRAY') {
                $group_destinations{$channel} = $nicks;
            }
            
            # Wha?
            else {
                $log->error("send_to: Don't know what to do with $channel => $nicks, ignoring.");
            }

        }
    }

    # Wha?
    else {
        $log->error("send_to: Don't know what to do with $to, ignore.");
        return;
    }

    # Internal function for chunking the message
    my $message_chunks = sub {
        my $message = shift;
        my @chunks;
        while (length $message > 400) {
            my $chunk = substr $message, 0, 400;
            $message  = substr $message, 400;
            push @chunks, $chunk.'\\';
        }
        push @chunks, $message;
        return @chunks;
    };

    # Handle group messages
    for my $channel (keys %group_destinations) {
        my $nicks = $group_destinations{$channel};

        # For each message line
        for my $message (@messages) {

            # Prepend any nicks we have
            if (@$nicks) {
                $message = join(',', @$nicks).': '.$message;
            }

            # Post the message by chunks
            post irc => privmsg => $channel => $_ 
                for $message_chunks->($message);
        }
    }

    # Send out the private messages
    for my $nick (keys %private_destinations) {

        # For each message line, post it to the nick in chunks
        for my $message (@messages) {
            post irc => privmsg => $nick => $_
                for $message_chunks->($message);
        }
    }

};

=head2 on reply_to_sender EVENT, MESSAGE

Sends the C<MESSAGE> back to the nick that sent the given C<EVENT>. The C<EVENT> should be a L<Bot::Net::Message> object. The C<MESSAGE> may be broken up and chunked as specified in L</send_to>.

This method will reply back to a user in all the channels it received the message in if the C<EVENT> was sent to a channel (or group of channels) or will send privately back if the C<EVENT> was private.

=cut

on reply_to_sender => run {
    my $event   = get ARG0;
    my $message = get ARG1;

    if ($event->public) {
        my %send_to = map { $_ => $event->sender_nick } 
                         @{ $event->recipient_groups };
        yield send_to => \%send_to => $message;
    }

    else {
        yield send_to => $event->sender_nick => $message;
    }
};

=head2 on reply_to_sender_privately EVENT, MESSAGE

Sends the C<MESSAGE> back to the nick that sent the given C<EVENT>, but via a private message directly to their nick, even if the original C<EVENT> took place as a channel message.

=cut

on reply_to_sender_privately => run {
    my $event   = get ARG0;
    my $message = get ARG1;

    yield send_to => $event->sender_nick => $message;
};

=head2 on reply_to_sender_group EVENT, CHANNEL, MESSAGE

Sends the C<MESSAGE> back to the nick that sent the given C<EVENT>, but via the public group name in the C<CHANNEL> argument.

=cut

on reply_to_sender_group => run {
    my $event   = get ARG0;
    my $channel = get ARG1;
    my $message = get ARG2;

    yield send_to => { $channel => $event->sender_nick } => $message;
};

=head2 on reply_to_general EVENT, MESSAGE

This is similar to L</reply_to_sender>, except that if sent to a channel, the sender will not be identified by nick.

=cut

on reply_to_general => run {
    my $event   = get ARG0;
    my $message = get ARG1;

    if ($event->public) {
        yield send_to => $event->recipient_groups => $message;
    }

    else {
        yield send_to => $event->sender_nick => $message;
    }
};

=head2 on bot quit

This causes the IRC client to close down the connection and quit.

=cut

on bot_quit => run {
    my $message = get ARG0;

    recall('log')->warn("Quitting the IRC connection.");
    post irc => quit => ($message || 'Quitting.');

    post irc => unregister => 'all';
    forget 'irc';
};

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
