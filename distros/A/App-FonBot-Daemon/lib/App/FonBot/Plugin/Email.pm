package App::FonBot::Plugin::Email;

our $VERSION = '0.001';

use v5.14;
use strict;
use warnings;

use Apache2::Authen::Passphrase qw/pwcheck/;
use Email::Sender::Simple qw/sendmail/;
use Email::Simple;
use Email::MIME;
use Linux::Inotify2 qw/IN_MOVED_TO/;
use File::Slurp qw/read_file/;
use POE;
use Log::Log4perl qw//;

use File::Glob qw/bsd_glob GLOB_NOSORT/;
use Text::ParseWords qw/shellwords/;

use App::FonBot::Plugin::Common;
use App::FonBot::Plugin::Config qw/$email_batch_seconds $email_from $email_subject/;

##################################################

my $log=Log::Log4perl->get_logger(__PACKAGE__);

my %queues;
my %queue_alarms;
my $session;
my $inotify;

sub init{
	return unless $email_from && $email_subject;
	$log->info('initializing '.__PACKAGE__);
	$session = POE::Session->create(
		inline_states => {
			_start => \&email_start,
			send_message => \&email_send_message,
			flush_queue => \&email_flush_queue,
			inotify_readable => sub{
				$_[HEAP]{inotify}->poll
			},
			shutdown => sub{
				$_[KERNEL]->select_read($inotify)
			}
		},
	);
}

sub fini{
	$log->info('finishing '.__PACKAGE__);
	POE::Kernel->post($session, 'shutdown')
}


sub email_handle_new{
	for my $file (bsd_glob 'Maildir/new/*', GLOB_NOSORT) {
		my $email=Email::MIME->new(scalar read_file $file);

		#untaint $file
		$file =~ /^(.*)$/;
		$file = $1;

		unlink $file;
		return unless defined $email;

		my $replyto=$email->header('From');
		return unless defined $replyto;

		my ($user,$password)=split ' ', $email->header('Subject'), 2;
		chomp $password;

		$log->debug("Processing email from $user");

		eval { pwcheck $user, $password };
		if ($@) {
			$log->debug("Incorrect credentials in email subject from user $user. Exception: $@");
			POE::Kernel->yield(send_message => $replyto, "Incorrect credentials");
			return
		}

		$ok_user_addresses{"$user EMAIL $replyto"}=1;

		my $process_email_part = sub {
			local *__ANON__ = "process_email_part";	#Name this sub. See http://www.perlmonks.org/?node_id=304883

			my $part=$_[0];
			return unless $part->content_type =~ /text\/plain/;

			my @lines=split '\n', $part->body;

			for my $line (@lines) {
				last if $line =~ /^--/;
				$log->debug("Command received via email from $user: $line");
				sendmsg $user, undef, "EMAIL '$replyto'", shellwords $line
			}
		};

		$email->walk_parts($process_email_part);
	}
}

sub email_start{
	$_[KERNEL]->alias_set('EMAIL');
	$_[HEAP]{inotify} = Linux::Inotify2->new;
	$_[HEAP]{inotify}->watch('Maildir/new/',IN_MOVED_TO,\&email_handle_new);

	open $inotify,'<&=',$_[HEAP]{inotify}->fileno;
	$_[KERNEL]->select_read($inotify, 'inotify_readable');
	email_handle_new
}

sub email_send_message{
	my ($address, $message) = @_[ARG0,ARG1];

	$queues{$address}.=$message."\n";
	if (defined $queue_alarms{$address}) {
		$_[KERNEL]->delay_adjust($queue_alarms{$address}, $email_batch_seconds)
	} else {
		$queue_alarms{$address}=$_[KERNEL]->delay_set(flush_queue => $email_batch_seconds, $address)
	}
}

sub email_flush_queue{
	my ($queue) = $_[ARG0];
	return unless exists $queues{$queue};

	my $email=Email::Simple->create(
		header => [
			From => $email_from,
			To => $queue,
			Subject => $email_subject,
		],
		body => $queues{$queue}
	);

	delete $queues{$queue};
	delete $queue_alarms{$queue};

	$log->debug("Sending email to $queue");

	eval {
		sendmail $email
	} or $log->error("Could not send email: " . $@->message);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::FonBot::Plugin::Email - FonBot plugin for receiving commands and sending messages through emails

=head1 SYNOPSIS

    use App::FonBot::Plugin::Email;
    App::FonBot::Plugin::Email->init;
    ...
    App::FonBot::Plugin::Email->fini;

=head1 DESCRIPTION

This FonBot plugin provides email receiving/sending features to B<fonbotd>. Emails are read from F<Maildir/> and are sent through C<Email::Sender::Simple>.

=head1 CONFIGURATION VARIABLES

These are the L<App::FonBot::Plugin::Config> configuration variables used in this module

=over

=item C<$email_batch_seconds>

When receiving an email send request, C<App::FonBot::Plugin::Email> waits this many seconds for further email send requests to the same email address. The timer is reset for each email send request. When the timer expires, all pending send requests are batched and sent as one email.

=item C<$email_from>

C<From:> header of all emails sent by this plugin. If not set the email plugin is disabled.

=item C<$email_subject>

C<Subject:> header of all emails sent by this plugin. If not set the email plugin is disabled.

=back

=head1 AUTHOR

Marius Gavrilescu C<< marius@ieval.ro >>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2015 Marius Gavrilescu

This file is part of fonbotd.

fonbotd is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

fonbotd is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with fonbotd.  If not, see <http://www.gnu.org/licenses/>
