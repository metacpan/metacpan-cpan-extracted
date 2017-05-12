package App::FonBot::Plugin::IRC;

our $VERSION = '0.001';

use v5.14;
use strict;
use warnings;

use Apache2::Authen::Passphrase qw/pwcheck/;
use IRC::Utils qw/parse_user/;
use Log::Log4perl qw//;
use POE;
use POE::Component::IRC qw//;

use Text::ParseWords qw/shellwords/;
use subs qw/shutdown/;

use App::FonBot::Plugin::Common;

##################################################

my %selves;

sub init{
	my ($ns)=@_;

	my $self=$ns->new;
	$self->{log}->info("initializing $ns");
	tie my %nick_to_username, DB_File => "nick_to_username-$ns.db";
	$self->{nick_to_username}=\%nick_to_username;
	$selves{$ns}=$self
}

sub fini{
	my ($ns)=@_;

	$selves{$ns}->{log}->info("finishing $ns");
	$selves{$ns}->{irc}->yield(shutdown => "finishing $ns") if defined $selves{$ns}->{irc};
	untie $selves{$ns}->{nick_to_username};
	POE::Kernel->post($selves{$ns}->{session} => 'shutdown');
	delete $selves{$ns}
}

##################################################

sub new{
	my ($ns)=@_;

	my $self = {
		prefix => {},
		log => Log::Log4perl->get_logger($ns),
	};

	bless $self, $ns;

	$self->{session} = POE::Session->create(
		object_states => [ $self => [ '_start', 'send_message', 'irc_001', 'irc_msg', 'irc_public', 'shutdown' ] ],
	);

	$self
}

sub irc_msg{
	my ($from, $msg, $self)=@_[ARG0,ARG2,OBJECT];
	my $nick=parse_user $from;

	my $username=$self->{nick_to_username}{$from};
	my $address=$_[KERNEL]->alias_list;
	$address.=" $nick";

	chomp $msg;
	my @args=shellwords $msg;
	my $cmd=shift @args;

	local $_ = $cmd;
	if (/^myid$/i){
		$self->{irc}->yield(privmsg => $nick, $from);
	} elsif (/^login$/i) {
		my ($user, $pass) = @args;

		eval { pwcheck $user, $pass };

		if ($@) {
			$self->{log}->debug("Login for $user failed");
			$self->{irc}->yield(privmsg => $nick, 'Bad username/password combination');
		} else {
			$self->{log}->debug("Login for $user succeded");
			$self->{nick_to_username}{$from} = $user;
			$self->{irc}->yield(privmsg => $nick, "Logged in as $user");
		}
	} elsif (/^logout$/i){
		delete $self->{nick_to_username}{$from};
	} elsif (/^prefix$/i){
		if (defined $username) {
			$self->{prefix}{$username} = [@args];
		} else {
			$self->{irc}->yield(privmsg => $nick, 'You are not logged in. Say "login your_username your_password" (where your_username and your_password are your login credentials) to login.');
		}
	} elsif (/^noprefix$/i){
		if (defined $username) {
			delete $self->{prefix}{$username}
		} else {
			$self->{irc}->yield(privmsg => $nick, 'You are not logged in. Say "login your_username your_password" (where your_username and your_password are your login credentials) to login.');
		}
	} else {
		if (defined $username) {
			$ok_user_addresses{"$username $address"}=1;
			$self->{log}->debug("Command $cmd @args from $username");
			if (exists $self->{prefix}{$username}) {
				sendmsg $username, undef, $address, @{$self->{prefix}{$username}}, $cmd, @args;
			} else {
				sendmsg $username, undef, $address, $cmd, @args;
			}
		} else {
			$self->{irc}->yield(privmsg => $nick, 'You are not logged in. Say "login your_username your_password" (where your_username and your_password are your login credentials) to login.');
		}
	}
}

sub irc_public{
	# Do nothing
}

sub irc_001{
	# Do nothing
}

sub send_message{
	my ($self, $address, $content)=@_[OBJECT, ARG0, ARG1];
	$self->{irc}->yield(privmsg => $address, $_) for map {unpack '(A400)*'} split "\n", $content
}

sub shutdown{
	$_[KERNEL]->alias_remove($_) for $_[KERNEL]->alias_list;
}

sub _start { ... }

1
