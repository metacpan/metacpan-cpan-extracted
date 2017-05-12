package App::Devbot;

use v5.14;
use strict;
use warnings;
our $VERSION = 0.001004;

use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::IRC::Plugin::NickServID;

use File::Slurp qw/append_file/;
use IRC::Utils qw/parse_user/;

use Getopt::Long;
use POSIX qw/strftime/;
use Regexp::Common qw /net/;

##################################################

my $nick='devbot';
my $password;
my $server='irc.oftc.net';
my $port=6697;
my $ssl=1;
my @channels;
my $trace=0;

my $log=1;
my $store_files=0;

GetOptions (
  "nick=s" => \$nick,
  "password=s" => \$password,
  "server=s" => \$server,
  "port=i" => \$port,
  "ssl!" => \$ssl,
  "channel=s" => \@channels,
  "log!" => \$log,
  "store-files!" => \$store_files,
  "trace!" => \$trace,
);

my $irc;

sub mode_char {
  my ($channel, $nick)=@_;
  return '~' if $irc->is_channel_owner($channel, $nick);
  return '&' if $irc->is_channel_admin($channel, $nick);
  return '@' if $irc->is_channel_operator($channel, $nick);
  return '%' if $irc->is_channel_halfop($channel, $nick);
  return '+' if $irc->has_channel_voice($channel, $nick);
  return ' '
}

sub log_event{
  return unless $log;
  my ($channel, @strings) = @_;
  my $file=strftime '%F', localtime;
  mkdir 'logs';
  mkdir "logs/$channel";
  append_file "logs/$channel/$file.txt", strftime ('%T ', localtime), @strings, "\n";
}

sub bot_start{
  $irc->plugin_add (NickServID => POE::Component::IRC::Plugin::NickServID->new(Password => $password)) if defined $password;
  $irc->plugin_add (AutoJoin => POE::Component::IRC::Plugin::AutoJoin->new(
	Channels => \@channels,
	RejoinOnKick => 1,
	Rejoin_delay => 10,
	Retry_when_banned => 60,
  ));

  $server = $1 if $server =~ /^($RE{net}{domain})$/;
  $port   = $1 if $port =~ /^([0-9]+)$/;

  $irc->yield(register => "all");
  $irc->yield(
	connect => {
	  Nick     => $nick,
	  Username => 'devbot',
	  Ircname  => "devbot $VERSION",
	  Server   => $server,
	  Port     => $port,
	  UseSSL   => $ssl,
	}
  );
}

sub on_public{
  my ($fulluser, $channels, $message)=@_[ARG0, ARG1, ARG2];
  my $nick=parse_user $fulluser;

  for (@$channels) {
	my $mode_char=mode_char $_, $nick;
	log_event $_, "<$mode_char$nick> $message";
  }
}

sub on_ctcp_action{
  my ($fulluser, $channels, $message)=@_[ARG0, ARG1, ARG2];
  my $nick=parse_user $fulluser;

  log_event $_, "* $nick $message" for @$channels;
}

sub on_join{
  my ($fulluser, $channel)=@_[ARG0, ARG1];
  my ($nick, $user, $host)=parse_user $fulluser;

  log_event $channel, "-!- $nick [$user\@$host] has joined $channel";
}

sub on_part{
  my ($fulluser, $channel, $message)=@_[ARG0, ARG1, ARG2];
  my ($nick, $user, $host)=parse_user $fulluser;

  log_event $channel, "-!- $nick [$user\@$host] has left $channel [$message]";
}

sub on_kick{
  my ($fulluser, $channel, $target, $message)=@_[ARG0, ARG1, ARG2, ARG3];
  my $nick=parse_user $fulluser;

  log_event $channel, "-!- $target was kicked from $channel by $nick [$message]";
}

sub on_mode{
  my ($fulluser, $channel, @args)=@_[ARG0 .. $#_];
  my $nick=parse_user $fulluser;
  my $mode=join ' ', @args;

  log_event $channel, "-!- mode/$channel [$mode] by $nick";
}

sub on_topic{
  my ($fulluser, $channel, $topic)=@_[ARG0, ARG1, ARG2];
  my $nick=parse_user $fulluser;

  log_event $channel, "-!- $nick changed the topic of $channel to: $topic" if $topic;
  log_event $channel, "-!- Topic unset by $nick on $channel" unless $topic;
}

sub on_nick{
  my ($fulluser, $nick, $channels)=@_[ARG0, ARG1, ARG2];
  my $oldnick=parse_user $fulluser;

  log_event $_, "-!- $oldnick is now known as $nick" for @$channels;
}

sub on_quit{
  my ($fulluser, $message, $channels)=@_[ARG0, ARG1, ARG2];
  my ($nick, $user, $host)=parse_user $fulluser;

  log_event $_, "-!- $nick [$user\@$host] has quit [$message]" for @$channels;
}

sub on_dcc_request{
  return unless $store_files;
  my ($fulluser, $type, $cookie, $name)=@_[ARG0, ARG1, ARG3, ARG4];
  my $nick=parse_user $fulluser;
  return unless $type eq 'SEND';
  return unless $irc->nick_channels($nick);
  return if $name =~ m,/,;

  mkdir 'files';
  $irc->yield(dcc_accept => $cookie, "files/$name");
}

sub run{
  $irc=POE::Component::IRC::State->spawn();

  POE::Session->create(
	inline_states => {
	  _start  => \&bot_start,
	  irc_public => \&on_public,
	  irc_ctcp_action => \&on_ctcp_action,
	  irc_join => \&on_join,
	  irc_part => \&on_part,
	  irc_kick => \&on_kick,
	  irc_mode => \&on_mode,
	  irc_topic => \&on_topic,
	  irc_nick => \&on_nick,
	  irc_quit => \&on_quit,
	  irc_dcc_request => \&on_dcc_request
	},
	options => {
	  trace => $trace
	}
  );

  $poe_kernel->run();
}

1;

__END__

=head1 NAME

App::Devbot - IRC bot which helps development

=head1 SYNOPSIS

  use App::Devbot;
  App::Devbot->run;

=head1 DESCRIPTION

App::Devbot is an IRC bot which helps developers collaborate.

Right now, it only does channel logging and file storage. It might do more in the future.

=head1 OPTIONS

=over

=item B<--nick> I<nickname>

The nickname of devbot. Defaults to devbot.

=item B<--password> I<password>

If supplied, identify to NickServ with this password

=item B<--server> I<hostname>

The server to connect to. Defaults to irc.oftc.net.

=item B<--port> I<port>

The port to connect to. Defaults to 6697.

=item B<--ssl>, B<--no-ssl>

B<--ssl> enables connecting to the server with SSL, B<--no-ssl> disables this. Defaults to B<--ssl>.

=item B<--channel> I<channel>

Makes devbot connect to I<channel>. Can be supplied multiple times for multiple channels. Has no default value.

=item B<--log>, B<--no-log>

B<--log> enables logging events to 'logs/I<CHANNEL>/I<DATE>.txt'. B<--no-log> disables logging. Defaults to B<--log>.

=item B<--store-files>, B<--no-store-files>

B<--store-files> enables storing files received via DCC to 'files/I<FILENAME>'. Files are only accepted if the sender and devbot share a channel. B<Only use when all channel users are trusted>. B<--no-store-files> disables storing files. Defaults to <--no-store-files>.

=item B<--trace>, B<--no-trace>

B<--trace> enables POE::Component::IRC::State tracing. Useful for debugging. B<--no-trace> disables tracing. Defaults to B<--no-trace>.

=back

=head1 CAVEATS

As stated above, the B<--store-files> option should only be used on private channels where every user is trusted.

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
