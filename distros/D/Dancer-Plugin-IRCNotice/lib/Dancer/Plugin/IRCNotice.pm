package Dancer::Plugin::IRCNotice;

use 5.008_005;
use strict;
use warnings;

use Carp 'croak';
use Dancer ':syntax';
use Dancer::Plugin;
use IO::Socket::IP;

our $VERSION = '0.06';

our %TYPES = (
  notice  => 'NOTICE',
  message => 'PRIVMSG',
);

register notify => sub {
  my ($message) = @_;

  info "Sending notification: $message";

  my $config = plugin_setting;

  $config->{host}    ||= 'chat.freenode.net';
  $config->{nick}    ||= sprintf 'dpin%04u', int(rand() * 10000);
  $config->{name}    ||= $config->{nick};
  $config->{channel} ||= '#dpintest';
  $config->{type}    ||= 'notice';

  croak "Invalid type settings $config->{type}"
    unless exists $TYPES{ $config->{type} };

  # Add default port
  $config->{host} .= ':6667' unless $config->{host} =~ /:\d+$/;

  my $socket = IO::Socket::IP->new($config->{host})
    or warning "Cannot create socket: $@" and return;

  # TODO error handling srsly

  info "Registering as $config->{nick}";

  $socket->say("NICK $config->{nick}");
  $socket->say("USER $config->{nick} . . :$config->{name}");

  while (my $line = $socket->getline) {
    info "Got $line";

    if ($line =~ /End of \/MOTD/) {
      info "Sending notice to $config->{channel}";

      $socket->say("$TYPES{$config->{type}} $config->{channel} :$message");
      $socket->say('QUIT');

      info 'Notice sent';
      return;
    }
  }

  info 'Notice not sent';
  return;
};

register_plugin;

1;
__END__

=encoding utf-8

=head1 NAME

Dancer::Plugin::IRCNotice - Send IRC notices from your dancer app

=head1 SYNOPSIS

  use Dancer::Plugin::IRCNotice;

  notify('This is a notification');

=head1 DESCRIPTION

Dancer::Plugin::IRCNotice provides a quick and dirty way to send IRC NOTICEs to
a specific channel.

This is B<very alpha> software right now.  No error checking is done.

=head1 CONFIGURATION

  plugins:
    IRCNotice:
      host: 'chat.freenode.net'
      nick: 'testnick12345'
      name: 'Dancer::Plugin::IRCNotify'
      channel: '#dpintest'
      type: 'notice'

The host, nick, name, and channel should be pretty obvious.

The type parameter lets you pick the type of message to send.  The default is
"notice" which sends a notice to the channel.  You can also choose "message"
which well send a normal message to the channel.

=head1 TODO

This is so bootleg, it really needs to be cleaned up to handle IRC correctly.
Unfortunately, all of the IRC modules I saw on cpan are event based
monstrosities so this just uses L<IO::Socket::IP> to connect.

The notify routine should probably let you override the settings or maybe I
should use something like L<Dancer::Plugin::DBIC> to define multiple notifiers
that can then be used.

A connection to IRC must be made for each notification presently.  Instead, it
should try to keep a connection open and reuse it or something.

=head1 AUTHOR

Alan Berndt E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 Alan Berndt

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
