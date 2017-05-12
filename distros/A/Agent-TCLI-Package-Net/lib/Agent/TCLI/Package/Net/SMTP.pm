package Agent::TCLI::Package::Net::SMTP;
#
# $Id: SMTP.pm 74 2007-06-08 00:42:53Z hacker $
#
=pod

=head1 NAME

Agent::TCLI::Package::Net::SMTP

=head1 SYNOPSIS

From within a TCLI Agent session:


=head1 DESCRIPTION

This module provides a package of commands for the TCLI environment. Currently
one must use the TCLI environment (or browse the source) to see documentation
for the commands it supports within the TCLI Agent.

Sends a standard SMTP mail message.

=head1 INTERFACE

This module must be loaded into a Agent::TCLI::Control by an
Agent::TCLI::Transport in order for a user to interface with it.

=cut

use warnings;
use strict;

use Object::InsideOut qw(Agent::TCLI::Package::Base);

use POE;
use POE::Component::Client::SMTP;
use Email::Simple::Creator;
use File::Slurp;
use Data::Dump qw(pp);
use Agent::TCLI::Command;
use Agent::TCLI::Parameter;
use Getopt::Lucid qw(:all);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: SMTP.pm 74 2007-06-08 00:42:53Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard <attribute>
methods unless otherwise noted.

These attrbiutes are generally internal and are probably only useful to
someone trying to enhance the functionality of this Package module.

=over

=cut

=back

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance TCLI.

=over

=item new ( hash of attributes )

Usually the only attributes that are useful on creation are the
verbose and do_verbose attrbiutes that are inherited from Agent::TCLI::Base.

=cut

sub _preinit :PreInit {
	my ($self,$args) = @_;

	$args->{'name'} = 'tcli_smtp';

	$args->{'session'} = POE::Session->create(
      object_states => [
          $self => [qw(
          	_start
          	_stop
          	_shutdown
          	_default
          	_child

			establish_context
			send
			SendMailSuccess
			SendMailFailure
			settings
			show
			)],
      ],
	);

}

sub _init :Init {
	my $self = shift;

	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: from
  constraints:
    - EMAIL
  default: tcli_agent@example.com
  help: The sender's email address
  manual: >
    This holds the sender's email address.
  type: Param
---
Agent::TCLI::Parameter:
  name: to
  constraints:
    - EMAIL_LOOSE
  help: The recipiants email address
  manual: >
    This holds a list of recipients. Note that To/CC/BCC fields are separated
    in your email body. From the SMTP server's point of view
    (and from this component's too) there is no difference as
    who is To, who CC and who BCC.
    The bottom line is: be careful how you construct your email message.
  type: Param
---
Agent::TCLI::Parameter:
  name: body
  help: the body of the email
  manual: >
    The textual part of hte email message, or the MIME content if so inclined.
  type: Param
---
Agent::TCLI::Parameter:
  name: subject
  aliases: subj
  help: the subject line
  manual: >
    The subject line for the message.
  type: Param
---
Agent::TCLI::Parameter:
  name: server
  default: localhost
  help: The SMTP server to use.
  manual: >
    The name or address of the mail server that will accept delivery or relay
    the mail message.
  type: Param
---
Agent::TCLI::Parameter:
  name: port
  help: Port SMTP server is listening on
  constraints:
    - UINT
  class: numeric
  default: 25
  manual: >
    Sometimes, SMTP servers are set to listen to other ports,
    in which case you need to set this parameter to the correct
    value to match your setup.
  type: Param
---
Agent::TCLI::Parameter:
  name: timeout
  constraints:
    - UINT
  class: numeric
  default: 30
  help: Timeout in seconds
  manual: >
    The timeout in seconds for the SMTP transaction. The default is 30 seconds.
  type: Param
---
Agent::TCLI::Parameter:
  name: textfile
  constraints:
    - ASCII
  help: A file of plain text for the message body.
  manual: >
    The textfile will be used as the message body for sending an email. It
    should not include headers. If the file cannot be found, the request will
    fail. Use Unix style path names.
  type: Param
---
Agent::TCLI::Parameter:
  name: msgfile
  constraints:
    - ASCII
  help: A file of plain text for the message body.
  manual: >
    The msgfile will be used as the entire message for sending an email. It
    should include headers. If the file cannot be found, the request will
    fail. Use Unix style path names. The to and from must still be defined,
    though they need not match what is in the msg.
  type: Param
---
Agent::TCLI::Command:
  name: smtp
  call_style: session
  command: tcli_smtp
  contexts:
    ROOT: smtp
  handler: establish_context
  help: smtp client to send mail
  manual: >
    Send mail to aSMTP server
  topic: net
  usage: smtp send to=joe@example.com from=jane@example.com subject=Hi body="hi"
---
Agent::TCLI::Command:
  name: send
  call_style: session
  command: tcli_smtp
  contexts:
    smtp: send
  handler: send
  help: send a mail message
  manual: >
    Send mail to a SMTP server. There are many parameters that are required to
    properly construct the message.
  parameters:
    to:
    from:
    body:
    timeout:
    subject:
    server:
    port:
  required:
    to:
  topic: net
  usage: smtp send to=joe@example.com from=jane@example.com subject=Hi body="hi"
---
Agent::TCLI::Command:
  name: sendtext
  call_style: session
  command: tcli_smtp
  contexts:
    smtp: sendtext
  handler: send
  help: send a mail message
  manual: >
    Send mail to a SMTP server when the body is from a text file on the local
    host system.
  parameters:
    to:
    from:
    textfile:
    timeout:
    subject:
    server:
    port:
  required:
    to:
    textfile:
  topic: net
  usage: smtp sendtext to=joe@example.com from=jane@example.com subject=Hi textfile="/tmp/hello.txt"
---
Agent::TCLI::Command:
  name: sendmsg
  call_style: session
  command: tcli_smtp
  contexts:
    smtp: sendmsg
  handler: send
  help: send a mail message
  manual: >
    Send mail to a SMTP server when the body is from a text file on the local
    host system.
  parameters:
    to:
    from:
    msgfile:
    timeout:
    subject:
    server:
    port:
  required:
    to:
    msgfile:
  topic: net
  usage: smtp sendmsg to=joe@example.com msgfile="/tmp/hello.msg"
---
Agent::TCLI::Command:
  name: set
  call_style: session
  command: tcli_smtp
  contexts:
    smtp: set
  handler: settings
  help: set defaults for smtp messages
  parameters:
    to:
    from:
    body:
    timeout:
    subject:
    server:
    port:
  topic: network
  usage: smtp set server=mx.example.com
---
Agent::TCLI::Command:
  name: show
  call_style: session
  command: tcli_smtp
  contexts:
    smtp: show
  handler: show
  help: show current settings
  parameters:
    to:
    from:
    body:
    timeout:
    subject:
    server:
    port:
  topic: network
  usage: smtp show timeout
...

}


sub _start {
	my ($kernel,  $self,  $session) =
      @_[KERNEL, OBJECT,   SESSION];
	$self->Verbose("_start: tcli http starting");

	# are we up before OIO has finished initializing object?
	if (!defined( $self->name ))
	{
		$kernel->yield('_start');
		return;
	}

	# There is only one command object per TCLI
    $kernel->alias_set($self->name);


	$self->Verbose(" Dump ".$self->dump(1),3 );

}

sub _stop {
    my ($kernel,  $self,) =
      @_[KERNEL, OBJECT,];
	$self->Verbose("_stop: ".$self->name." stopping",2);
}

sub SendMailSuccess {
	my ($kernel,  $self,  $request) =
      @_[KERNEL, OBJECT,      ARG0];

	$request->Respond($kernel,"OK", 200);
	return
}

sub SendMailFailure {
	my ($kernel,  $self,  $request, $fail) =
      @_[KERNEL, OBJECT,      ARG0,  ARG1];

    $request->Respond($kernel, "Failed: ".pp($fail),400);
	$self->Verbose( "SendMailFailed: ".pp($fail));
}

sub send {
    my ($kernel,  $self, $session, $request, ) =
      @_[KERNEL, OBJECT,  SESSION,     ARG0, ];

	my $txt = '';
	my $param;
	my $command = $request->command->[0];
	my $cmd = $self->commands->{$command};

	return unless ( $param = $cmd->Validate($kernel, $request, $self) );

	$self->Verbose("send: to(".$param->{'to'}.") ",2);
	$self->Verbose("send: param dump ",,$param);

	# Build email message from parts.
	my ($email, $body);

	if ($command eq 'send')
	{
		$email = Email::Simple->create(
			header => [
				From    => $param->{'from'},
				To      => $param->{'to'},
				Subject => $param->{'subject'},
			],
			body => $param->{'body'},
		);

		$body = $email->as_string;
	}
	elsif ($command eq 'sendtext')
	{
		my $file = read_file( $param->{'textfile'}, err_mode => 'quiet' );

		unless (defined $file)
		{
			$request->Respond($kernel, "failed: sendtext file not found", 404);
			$self->Verbose("send: sendtext file not found (".$param->{'textfile'}.") ");
			return
		}

		$email = Email::Simple->create(
			header => [
				From    => $param->{'from'},
				To      => $param->{'to'},
				Subject => $param->{'subject'},
			],
			body => $file,
		);

        $body = $email->as_string;
	}
	elsif ($command eq 'sendmsg')
	{
		my $file = read_file( $param->{'msgfile'}, err_mode => 'quiet' );

		unless (defined $file)
		{
			$request->Respond($kernel, "failed: sendmsg file not found", 404);
			$self->Verbose("send: sendmsg file not found (".$param->{'textfile'}.") ");
			return
		}

        $body = $file;
	}

    # Note that you are prohibited by RFC to send bare LF characters in e-mail
    # messages; consult: http://cr.yp.to/docs/smtplf.html
    $body =~ s/\n/\r\n/g;

	POE::Component::Client::SMTP->send(
		# Email related parameters
		From    => $param->{'from'},
		To      => $param->{'to'},
     	Body    => $body,

     	# server params
     	Port	=> $param->{'port'},
		Server  => $param->{'server'},
		Timeout => $param->{'timeout'},

		# POE related parameters
        Context			=> $request,
		Alias           => 'pococlsmtpX',
		SMTP_Success    => 'SendMailSuccess',
		SMTP_Failure    => 'SendMailFailure',
#		Debug			=>  0,
	);
}

=item show

This POE event handler executes the show commands.

=back

=cut

1;
#__END__

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Package::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut