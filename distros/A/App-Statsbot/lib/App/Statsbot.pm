package App::Statsbot;

use 5.014000;
use strict;
use warnings;

our $VERSION = '1.000';

use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::IRC::Plugin::Connector;
use POE::Component::IRC::Plugin::CTCP;
use IRC::Utils qw/parse_user/;

use Carp;
use DBI;
use DBD::SQLite;
use Text::ParseWords qw/shellwords/;
use Time::Duration qw/duration duration_exact/;
use Time::Duration::Parse qw/parse_duration/;

use List::Util qw/max/;

our $DEBUG = '';
our $TICK  = 10;
our $NICKNAME = 'statsbot';
our $SERVER = 'irc.freenode.net';
our $PORT = 6667;
our $SSL = '';
our @CHANNELS;
our $DB = '/var/lib/statsbot/db';

{
	my %cfg = (debug => \$DEBUG, tick => \$TICK, nickname => \$NICKNAME, server => \$SERVER, port => \$PORT, ssl => \$SSL, channels => \@CHANNELS, db => \$DB);
	for my $var (keys %cfg) {
		my $key = "STATSBOT_\U$var";
		${$cfg{$var}} = $ENV{$key} if exists $ENV{$key} && ref $cfg{$var} eq 'SCALAR';
		@{$cfg{$var}} = split ' ', $ENV{$key} if exists $ENV{$key} && ref $cfg{$var} eq 'ARRAY';
	}
}

my $dbh;
my $insert;
my $update;
my $irc;

my %state;

sub _yield { $irc->yield(@_) }
sub _nick_name { $irc->nick_name }

sub _uptime {
	my ($starttime, $nick) = @_;
	my $sth=$dbh->prepare('SELECT start,end FROM presence WHERE end > ? AND nick == ?');
	$sth->execute($starttime, $nick);

	my $uptime=0;
	while (my ($start, $end)=$sth->fetchrow_array) {
		$uptime+=$end-max($start,$starttime)
	}
	return $uptime
}

sub run {
	$irc=POE::Component::IRC::State->spawn;
	POE::Session->create(
		inline_states => {
			_start     => \&bot_start,
			irc_public => \&on_public,

			irc_chan_sync => \&tick,
			tick => \&tick,

			irc_disconnected => \&on_fatal,
			irc_error => \&on_fatal,
		},
		options => { trace => $DEBUG },
	);

	$dbh=DBI->connect("dbi:SQLite:dbname=$DB") or croak "Cannot connect to database: $!";
	$dbh->do('CREATE TABLE presence (start INTEGER, end INTEGER, nick TEXT)');
	$insert=$dbh->prepare('INSERT INTO presence (start, end, nick) VALUES (?,?,?)') or croak "Cannot prepare query: $!";
	$update=$dbh->prepare('UPDATE presence SET end = ? WHERE start == ? AND nick == ?') or croak "Cannot prepare query: $!";
	$poe_kernel->run();
};

sub tick{
	my %nicks = map {$_ => 1} $irc->nicks;
	for my $nick (keys %state) {
		$update->execute(time, $state{$nick}, $nick);
		delete $state{$nick} unless (exists $nicks{$nick});
		delete $nicks{$nick};
	}

	for (keys %nicks) {
		$state{$_}=time;
		$insert->execute($state{$_}, $state{$_}, $_);
	}
	$_[KERNEL]->delay(tick => $TICK);
}

sub bot_start{ ## no critic (RequireArgUnpacking)
	$_[KERNEL]->delay(tick => $TICK);

	$irc->plugin_add(CTCP => POE::Component::IRC::Plugin::CTCP->new(
		version => "Statsbot/$VERSION",
		source => 'https://metacpan.org/pod/App::Statsbot',
		userinfo => 'A bot which keeps logs and computes channel statistics',
		clientinfo => 'PING VERSION CLIENTINFO USERINFO SOURCE',
	));
	$irc->plugin_add(AutoJoin => POE::Component::IRC::Plugin::AutoJoin->new(
		Channels => [ @CHANNELS ],
		RejoinOnKick => 1,
		Rejoin_delay => 20,
		Retry_when_banned => 60,
	));
	$irc->plugin_add(Connecter => POE::Component::IRC::Plugin::Connector->new(
		servers => [ $SERVER ],
	));

	_yield(register => 'all');
	_yield(
		connect => {
			Nick     => $NICKNAME,
			Username => 'statsbot',
			Ircname  => 'Logging and statistics bot',
			Server   => $SERVER,
			Port     => $PORT,
			UseSSL   => $SSL,
		}
	);
}

sub on_fatal{ croak "Fatal error: $_[ARG0]" }

sub on_public{
	my ($targets,$message)=@_[ARG1,ARG2];
	my $botnick = _nick_name;

	if ($message =~ /^(?:$botnick[:,]\s*!?|\s*!)help/sx) {
		_yield(privmsg => $targets, 'Try !presence username interval [truncate]');
		_yield(privmsg => $targets, q/For example, !presence mgv '2 days'/);
		_yield(privmsg => $targets, q/or !presence mgv '1 year' 4/);
		return;
	}

	return unless $message =~ /^(?:$botnick[:,])?\s*!?presence\s*(.*)/sx;
	my ($nick, $time, $truncate) = shellwords $1;

	$truncate//=-1;

	unless (defined $time) {
		$time='1 days';
		$truncate=-1;
	}

	eval {
		$time = parse_duration $time;
	} or do {
		_yield(privmsg => $targets, "cannot parse timespec: $time");
		return;
	};

	my $uptime=_uptime time-$time, $nick;

	my $ret;
	if ($truncate == -1) {
		use integer;
		$ret=($uptime/3600).' hours';
	} else {
		$ret=duration $uptime,$truncate;
	}

	$time=duration_exact $time;

	_yield(privmsg => $targets, "$nick was here $ret during the last $time");
}


1;
__END__

=encoding utf-8

=head1 NAME

App::Statsbot - simple IRC bot that tracks time spent in a channel

=head1 SYNOPSIS

  use App::Statsbot;
  @App::Statsbot::CHANNELS = '#oooes';
  $App::Statsbot::DEBUG = 1;
  App::Statsbot->run

  # Bot will respond to queries of the forms:
  # < mgv> !presence mgv
  # < mgv>   presence mgv '1 day'
  # < mgv> BOTNICK: !presence mgv '1 year' 2
  # < mgv> BOTNICK:    presence   mgv

=head1 DESCRIPTION

App::Statsbot is a simple IRC bot that tracks the people that inhabit
a channel. It is able to answer queries of the form "In the last <time
interval>, how much time did <nick> spend in this channel?".

It is configured via global variables in the App::Statsbot package.
These variables are initialized from environment variables with names
of the form STATSBOT_DEBUG, STATSBOT_TICK, etc. In the case of array
variables, the environment variable is treated as a space separated
list. Each configuration variable has a default value used when it is
not set explicitly or via the environment.

=over

=item $DEBUG

If true, print some debug information. Defaults to false.

=item $TICK

How often (in seconds) to poll the channel for nicks. Defaults to 10
seconds.

=item $NICKNAME

The nickname of the bot. Defaults to "statsbot".

=item $SERVER

The IRC server. Defaults to "irc.freenode.net".

=item $PORT

The port. Defaults to 6667.

=item $SSL

If true, connect via SSL. Defaults to false.

=item @CHANNELS

Array of channels to connect to. Defaults to an empty array, which is
not very useful.

=item $DB

Path to SQLite database. Must be writable. Will be created if it does
not exist. Defaults to C</var/lib/statsbot/db>.

=back

After configuration, the bot can be started using the B<run> function,
which can be called as either a regular function or a method.

=head1 SEE ALSO

L<statsbot>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
