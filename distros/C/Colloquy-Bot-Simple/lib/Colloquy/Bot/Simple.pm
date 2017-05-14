############################################################
#
#   $Id: Simple.pm 518 2006-05-29 11:32:23Z nicolaw $
#   Colloquy::Bot::Simple - Simple robot interface for Colloquy
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Colloquy::Bot::Simple;
# vim:ts=4:sw=4:tw=78

use base qw(Chatbot::TalkerBot);

use strict;
no warnings qw(redefine);

use Exporter;
use Carp qw(croak cluck carp confess);
use Parse::Colloquy::Bot qw(:all);

use vars qw(@EXPORT @EXPORT_OK $VERSION);

@EXPORT = qw(&connect_through_firewall &connect_directly &daemonize);
@EXPORT_OK = qw(TB_TRACE TB_LOG);

$VERSION = '1.08' || sprintf('%d', q$Revision: 518 $ =~ /(\d+)/g);

sub TB_LOG { Chatbot::TalkerBot::TB_TRACE(@_); }
sub TB_TRACE { Chatbot::TalkerBot::TB_TRACE(@_); }

sub listenLoop {
	my $self = shift;
	my $callback = shift;
	my $interrupt = shift;
	
	# check that any supplied callback is a coderef 
	if ($callback && (ref( $callback ) ne 'CODE')) { die("The callback must be a code reference"); }
	if ($interrupt) { TB_LOG("Installing interrupt handler every $interrupt secs"); }
	
	my $STOPLOOP = 0;
	local $SIG{'ALRM'} = ($interrupt? sub { $callback->($self, 'ALRM'); alarm($interrupt); } : 'IGNORE');
	alarm($interrupt) if $interrupt;
	
	# enter event loop
	TB_LOG("Entering listening loop");
	my $socket = $self->{'connection'};

	while( <$socket> ) {
		# we don't know how long it will take to process this line, so stop interrupts
		alarm(0) if $interrupt;
		
		s/[\n\r]//g;
		
		# only pay any attention to that regular expression
		if ($self->{'AnyCommands'} == 1) {
			my $args = Parse::Colloquy::Bot::parse_line($_);
			$args->{alarm} = 0;

			TB_LOG("Attending: <$args->{msgtype}> = <$args->{text}>");
			$self->{'lines_in'} += 1;

			$STOPLOOP = $callback->($self, %{$args});
		}
		
		# command processing done, turn interrupts back on
		last if $STOPLOOP;
		alarm($interrupt) if $interrupt;
	}
	TB_LOG("Fallen out of listening loop");
}


sub new {
	my $class = shift;
	croak "Odd number of elements passed when even was expected"
		if @_ % 2;

	my $self = {};
	while (my $key = shift(@_)) {
		$self->{lc($key)} = shift(@_);
	}

	for my $key qw(username password host port) {
		unless (exists $self->{$key} && length($self->{$key})) {
			croak "No '$key' value was specified";
		}
	}

	my $socket = Chatbot::TalkerBot::connect_directly(
			$self->{host},
			$self->{port}
		);

	my $talker = $class->SUPER::new($socket, {
			Username => $self->{username},
			Password => $self->{password},
			UsernameResponse => $self->{usernameresponse} || '<USER> <PASS>',
			UsernamePrompt => $self->{usernameprompt} || 'HELLO colloquy',
			PasswordPrompt => $self->{passwordprompt} || '',
			PasswordResponse => $self->{passwordresponse} || '',
			LoginSuccess => $self->{loginsuccess} || 'MARK ---',
			LoginFail => $self->{loginfail} || 'Incorrect login',
			#NoCommands => 1,
		});

	return $talker;
}

sub _is_list {
	local $_ = shift || '';
	if (/^LIST.+\{(\w+?)\}\s*$/) {
		return '%'.$1;
	} elsif (/^OBSERVED\s+(\S+)\s+/) {
		return '@'.$1;
	}
	return undef;
}

# Daemonize self
sub daemonize {
	# Pass in the PID filename to use
	my $pidfile = shift || undef;

	# Boolean true will supress "already running" messages if you want to
	# spawn a process out of cron every so often to ensure it's always
	# running, and to respawn it if it's died
	my $cron = shift || 0;

	# Set the fname to the filename minus path
	(my $SELF = $0) =~ s|.*/||;
	$0 = $SELF;

	# Lazy people have to have everything done for them!
	$pidfile = "/tmp/$SELF.pid" unless defined $pidfile;

	# Check that we're not already running, and quit if we are
	if (-f $pidfile) {
		unless (open(PID,$pidfile)) {
			warn "Unable to open file handle PID for file '$pidfile': $!\n";
			exit 1;
		}
		my $pid = <PID>; chomp $pid;
		close(PID) || warn "Unable to close file handle PID for file '$pidfile': $!\n";

		# This is a good method to check the process is still running for Linux
		# kernels since it checks that the fname of the process is the same as
		# the current process
		if (-f "/proc/$pid/stat") {
			open(FH,"/proc/$pid/stat") || warn "Unable to open file handle FH for file '/proc/$pid/stat': $!\n";
			my $line = <FH>;
			close(FH) || warn "Unable to close file handle FH for file '/proc/$pid/stat': $!\n";
			if ($line =~ /\d+[^(]*\((.*)\)\s*/) {
				my $process = $1;
				if ($process =~ /^$SELF$/) {
					warn "$SELF already running at PID $pid; exiting.\n" unless $cron;
					exit 0;
				}
			}

		# This will work on other UNIX flavors but doesn't gaurentee that the
		# PID you've just checked is the same process fname as reported in you
		# PID file
		} elsif (kill(0,$pid)) {
			warn "$SELF already running at PID $pid; exiting.\n" unless $cron;
			exit 0;

		# Otherwise the PID file is old and stale and it should be removed
		} else {
			warn "Removing stale PID file.\n";
			unlink($pidfile) || warn "Unable to unlink PID file '$pidfile': $!\n";
		}
	}

	# Daemon parent about to spawn
	if (my $pid = fork) {
		warn "Forking background daemon, process $pid.\n";
		exit 0;

	# Child daemon process that was spawned
	} else {
		# Fork a second time to get rid of any attached terminals
		if (my $pid = fork) {
			warn "Forking second background daemon, process $pid.\n";
			exit 0;
		} else {
			unless (defined $pid) {
				warn "Cannot fork: $!\n";
				exit 2;
			}
			unless (open(FH,">$pidfile")) {
				warn "Unable to open file handle FH for file '$pidfile': $!\n";
				exit 3;
			}
			print FH $$;
			close(FH) || warn "Unable to close file handle FH for file '$pidfile': $!\n";

			# Sort out file handles and current working directory
			chdir '/' || warn "Unable to change directory to '/': $!\n";
			close(STDOUT) || warn "Unable to close file handle STDOUT: $!\n";
			close(STDERR) || warn "Unable to close file handle STDERR: $!\n";
			open(STDOUT,'>>/dev/null'); open(STDERR,'>>/dev/null');

			return $$;
		}
	}
}

1;

=pod

=head1 NAME

Colloquy::Bot::Simple - Simple robot interface for Colloquy

=head1 SYNOPSIS

 use Colloquy::Bot::Simple qw(daemonize);
  
 # Create a connection
 my $talker = Colloquy::Bot::Simple->new(
          host => '127.0.0.1',
          port => 1236,
          username => 'MyBot',
          password => 'topsecret',
     );
 
 # Daemonize in to the background
 daemonize("/tmp/MyBot.pid","quiet");
 
 # Execute callback on speech and "alarm" every 60 seconds
 $talker->listenLoop(\&event_callback, 60);

 # Tidy up and finish
 $talker->quit();
 exit;
 
 sub event_callback {
     my $talker = shift;
     my $event = @_ % 2 ? { alarm => 1 } : { @_ };
 
     if (exists $event->{alarm}) {
         print "Callback called as ALARM interrupt handler\n";
         # ... go check an RSS feed for new news items to inform
         #     your users about or something else nice maybe ...?
 
     } elsif (lc($event->{command}) eq 'hello') {
         $talker->whisper(
                 (exists $event->{list} ? $event->{list} : $event->{person}),
                 "Hi there $event->{person}"
             );
 
     } elsif ($event->{msgtype} eq 'TELL') {
         $talker->whisper($event->{person}, 'Pardon?');
     }
 
     # Return boolean false to continue the listenLoop
     return 0;
 }

=head1 DESCRIPTION

A very simple robot interface to connect and interact with a Colloquy talker,
based upon Chatbot::TalkerBot.

=head1 METHODS

=head2 new

=head2 daemonize

=head2 listenLoop

=head2 say

=head2 whisper

=head2 quit

=head1 TODO

Write some decent POD.

=head1 SEE ALSO

L<Chatbot::TalkerBot>, L<Parse::Colloquy::Bot>, L<Bundle::Colloquy::BotBot2>

=head1 VERSION

$Id: Simple.pm 518 2006-05-29 11:32:23Z nicolaw $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut






