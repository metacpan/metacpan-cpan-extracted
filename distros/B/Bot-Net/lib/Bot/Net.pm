use strict;
use warnings;

package Bot::Net;
use base qw/ Class::Data::Inheritable /;

our $VERSION = '0.1.0';

use Bot::Net::Config;
use Bot::Net::Log;

__PACKAGE__->mk_classdata(qw/ _bot_net /);

=head1 NAME

Bot::Net - run your very own IRC bot net

=head1 SYNOPSIS

If you're just using a L<Bot::Net>:

  cd MyBotNet
  bin/botnet run --server Main
  bin/botnet run --bot SomeBot

To create a new L<Bot::Net> application:

  bin/botnet net --name MyBotNet

TODO XXX FIXME Document automatic creation of new bots and servers...

If you're developing a new bot or something, you might find these useful:

  Bot::Net->log->debug("Debug message.");
  Bot::Net->log->error("Error message.");

  my $value = Bot::Net->config->bot('MyBot')->{'config'}{'value'};

=head1 DESCRIPTION

B<EXPERIMENTAL:> This module has just barely left the proof-of-concept phase. Much of the API is fluid and changing. If you're interested in contributing, please contact me at my email address at the bottom.

A nice way to create bots, networks of bots, and servers that run them. Currently, this system only provides tools for building IRC bots, but additional protocols could be added in the future. The aim is not to tie the system to any one architecture for the bots, but provide an easy way to build them and verify that they do what you want.

=head2 GOALS

The aim of this system is to provide a tool for creating a botnet for handling parallel tasks with communication primarily happening over IRC. The eventual goals of the system include:

=over

=item *

Provide easy to build and easy to understand mechanisms for building semi-autonomous agent-based systems (bots).

=item *

Automatically build the scaffolding for a L<Bot::Net> application, automatically create stubs for bots and servers, and generally give you some tools to get started quickly.

=item *

Provide a declarative syntax for creating bots and bot components.

=item *

Tools for initializing and managing the lifecycle of all your bots.

=item *

A server environment for helping you run your bots on one or more hosts that can communicate with one another.

=item *

A verification system for telling you whether or not your bots will talk to each other without getting confused or fail.

=back

=head2 WHY?

First, because breaking certain tasks into small hunks that can be handled by semi-autonomous agentsis a handy way to think about some problems. 

The original problem I wrote this system for is to handle the synchronization of data between lots of hosts. I had bots for pulling bits of data from each host, other bots for pushing bits of data back to each host, bots for pulling data from one host and pushing to another, bots for filtering the data so that it's in the correct format, etc. 

It quickly became a pain, so I built this to take away the pain.

Previously, I wrote another system, L<FleetConf>, to handle a very similar task. However, I am not very happy with how that turned out, so learning from my work there, I've built this system.

=head1 THIS OBJECT

This is the central singleton providing some basic services used by just about everything in the L<Bot::Net> system.

=head1 METHODS

=head2 bot_net

Returns the singleton object. Usually, you don't need to call this directly since all the L<Bot::Net> methods call this internally.

=cut

sub bot_net {
    my $class = shift;
    unless ($class->_bot_net) {
        $class->_bot_net(bless {}, $class);
    }
    return $class->_bot_net;
}

=head2 config

Return the configuration data for this application instance. See L<Bot::Net::Config> for additioanl details.

=cut

sub config {
    my $class = shift;
    my $self  = $class->bot_net;

    if (not defined $self->{config}) {
        $self->{config} = Bot::Net::Config->new;
    }

    return $self->{config};
}

=head2 log NAME

Retrieves a logger object for this application. If given a name, it will return a specific named logger. Otherwise, it returns the application default logger, named "Bot::Net".

See L<Bot::Net::Log>.

=cut

sub log {
    my $class = shift;
    my $self  = $class->bot_net;
    my $name  = shift || eval { Bot::Net->config->net('ApplicationClass') } 
                      || 'Bot::Net';

    if (not defined $self->{log}) {
        $self->{log} = Bot::Net::Log->new;
    }

    return $self->{log}->get_logger($name);
}

=head2 net_class NAMES

Given a list of names, it creates a class name for the current L<Bot::Net> application. 

  # Find the name of the Chatbot::Eliza bot in the local app
  my $class = Bot::Net->net_class('Bot', 'Chatbot', 'Eliza');

=cut

sub net_class {
    my $class = shift;
    my $app_class = $class->config->net('ApplicationClass');

    return scalar join '::', $app_class, @_;
}

=head2 short_name_for_bot CLASS

Returns the name of the bot.

=cut

sub short_name_for_bot {
    my $class = shift;
    my $bot_class = shift;

    my $app_class = $class->config->net('ApplicationClass');

    $bot_class =~ s/^\Q$app_class\E::Bot:://;

    return $bot_class;
}

=head2 short_name_for_server CLASS

Returns the name of the server.

=cut

sub short_name_for_server {
    my $class = shift;
    my $server_class = shift;

    my $app_class = $class->config->net('ApplicationClass');

    $server_class =~ s/^\Q$app_class\E::Server:://;

    return $server_class;
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
