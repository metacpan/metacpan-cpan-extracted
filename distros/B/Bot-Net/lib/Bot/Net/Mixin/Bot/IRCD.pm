use strict;
use warnings;

package Bot::Net::Mixin::Bot::IRCD;

use Bot::Net::Mixin;

use Scalar::Util qw/ reftype /;

=head1 NAME

Bot::Net::Mixin::Bot::IRCD - mixin class for building IRC daemon bots

=head1 SYNOPSIS

  # Build an Eliza chatbot directly on the server
  use strict;
  use warnings;

  package MyBotNet::Bot::ElizaOnServer;

  use Bot::Net::Bot;
  use Bot::Net::Mixin::Bot::IRCD;
  use Chatbot::Eliza; # available separately on CPAN

  on _start => run {
      # Make it easy for other sessions to talk to us
      get(KERNEL)->alias_set('eliza');
  };

  on bot startup => run {
      remember eliza => Chatbot::Eliza->new;
  };

  on bot message_to_me => run {
      my $event = getARG0;

      my $reply = recall('eliza')->transform( $event->message );
      yield reply_to_sender => $message, $reply;
  };

  on bot quit => run {
      # Clear the session alias for clean shutdown
      get(KERNEL)->alias_remove('eliza');
  };

  1;

Then in your server, you need something like this:

  use strict;
  use warnings;

  package MyBotNet::Server::Main;

  use Bot::Net::Server;
  use Bot::Net::Mixin::Server::IRC;

  use MyBotNet::Bot::ElizaOnServer;

  on _start => run {
      remember eliza => MyBotNet::Bot::ElizaOnServer->setup;
  };

  on server quit => run {

      # Clean up for clean shutdown
      forget 'eliza';
  };

  1;

=head1 DESCRIPTION

Some bots are best run direclty on the server itself. This is generally useful for handling channel or nick management services and other administrative tasks. A typical bot should run as a separate entity whenever possible. See L<Bot::Net::Mixin::Bot::IRC>.

Unlike stand-alone bots, an IRC daemon bot cannot be run using the L<botnet> command. Instead, they must be installed by a specific server and then are run as part of server startup via the L<botnet> command.

=head1 METHODS

=head2 default_configuration PACKAGE

Returns a bas configuration for an IRC daemon bot.

=cut

sub default_configuration {
    my $class   = shift;
    my $package = shift;

    my $name = Bot::Net->short_name_for_bot($package);
    $name =~ s/\W+/_/g;

    my $default_channel = Bot::Net->config->net('ApplicationName');
    $default_channel =~ s/\W+/_/g;

    return {
        alias        => $name,

        spoofing     => {
            nick    => $name,
            ircname => $name,
        },

        channels     => [ '#'.$default_channel ],
    };
}

=head1 BOT STATES

The following states are available for your bot to implement.

=head2 on bot connected

This is emitted as soon as the nick spoofing and initial channel setup has been setup.

=head2 on bot message_to_group EVENT

This state occurs when the bot observes a message sent to a channel it is in, but the message is not directed at the bot (i.e., is not prefixed with "MyNick:").

The C<EVENT> is a L<Bot::Net::Message> object setup to contain the group message.

=head2 on bot message_to_me EVENT

This state occurs when either the bot observes a message sent to a channel that it is in that has been prefixed with "MyNick:" or a private message was sent directly to the bot.

The C<EVENT> is a L<Bot::Net::Message> object setup for either a group or private message depending on which occurred. If a public message the "MyNick:" part of the message will have been stripped.

=head1 MIXIN STATES

=head2 on _start

Tells the server to spoof the bot's nick and registers to receive daemon events. It also sets up an alias for the session so that the server and other server bots may talk to your bot directly. The alias is set according to the "alias" configuration parameter.

It ends by firing the L</on bot connected> state.

=cut

on _start => run {
    my $alias    = recall [ config => 'alias' ];
    my $spoofed  = recall [ config => 'spoofing' ];
    my $channels = recall [ config => 'channels' ];

    get(KERNEL)->alias_set($alias) if $alias;

    recall('log')->info('Setting up nick spoofing as '
        .$spoofed->{nick});
    post ircd => register => 'all'; # TODO limit this to a subset

    # Make sure we are, in fact, ready when we report
    call ircd => add_spoofed_nick => $spoofed;
    recall('log')->info("BOT READY : nick $spoofed->{nick}");

    for my $channel (@{ $channels || [] }) {
        recall('log')->info('Joining '.$channel);
        post ircd => daemon_cmd_join => $spoofed->{nick}, $channel;
    }

    yield 'bot_connected';
};

=head2 on ircd_daemon_privmsg USERHOST, NICK, MESSAGE

Handles IRC messasges sent directly to the bot. This then emits the additional bot state L</on bot message_to_me>. It will be passed a single argument, the L<Bot::Net::Message> containting the message received.

=cut

on ircd_daemon_privmsg => run {
    my $userhost = get ARG0;
    my $me       = get ARG1;
    my $message  = get ARG2;

    my $my_nick = recall [ config => spoofing => 'nick' ];

    my ($nick, $host) = split /!/, $userhost;

    # Only respond to messages directly to me
    if ($me eq $my_nick) {
        my $event = Bot::Net::Message->new({
            sender_nick     => $nick,
            sender_host     => $host,
            recipient_nicks => $me,
            message         => $message,
            private         => 1,
        });

        yield bot_message_to_me => $event;
    }
};

=head2 ircd_daemon_public USERHOST, CHANNEL, MESSAGE

Handles any public messages stated in a channel the bot is in. It will emit either a L</on bot message_to_group> state or L</on bot message_to_me> state depending on whether or not the message was prefixed with "MyNick:".

Both events will receive a single argument, the L<Bot::Net::Message> representing the message sent. The message will have the "MyNick:" prefix stripped on teh L</on bot message_to_me> message.

=cut

on ircd_daemon_public => run {
    my $userhost = get ARG0;
    my $channel  = get ARG1;
    my $message  = get ARG2;

    my $my_nick  = recall [ config => spoofing => 'nick' ];
    my $channels = recall [ config => 'channels' ];

    my ($nick, $host) = split /!/, $userhost;

    # FIXME This isn't a very good mechanism for determining if this spoofed
    # nick is in the channel since it could have changed.

    # Am I in this channel?
    if (grep { $_ eq $channel } @{ $channels || [] }) {
        my $state;
        if ($message =~ s/^\Q$my_nick\E:\s*//) {
            $state = 'message_to_me';
        }

        else {
            $state = 'message_to_group';
        }

        my $event = Bot::Net::Message->new({
            sender_nick      => $nick,
            sender_host      => $host,
            recipient_groups => $channel,
            message          => $message,
            public           => 1,
        });

        yield 'bot_' . $state => $event;
    }
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
    my $my_nick = recall [ config => spoofing => 'nick' ];

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
            post ircd => daemon_cmd_privmsg => $my_nick => $channel => $_ 
                for $message_chunks->($message);
        }
    }

    # Send out the private messages
    for my $nick (keys %private_destinations) {

        # For each message line, post it to the nick in chunks
        for my $message (@messages) {
            post ircd => daemon_cmd_privmsg => $my_nick => $nick => $_
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
    recall('log')->warn("Stopping spoofed server-side IRC bot.");

    my $alias   = recall [ config => 'alias' ];
    my $my_nick = recall [ config => spoofing => 'nick' ];

    post ircd => del_spoofed_nick => $my_nick => 'Quitting.';
    post ircd => unregister => 'all';

    get(KERNEL)->alias_remove($alias) if $alias;
};

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
