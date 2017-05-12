package Audio::AMaMP;

use 5.6.0;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw();

our $VERSION = '0.3';

require XSLoader;
XSLoader::load('Audio::AMaMP', $VERSION);


# Constructor.
sub new {
	return bless {}, shift;
}


# This starts the core.  Essentially OO-wraps the C function.
sub startCore {
	# Get input parameters and check.
	my ($self, $corePath, $inputFile) = @_;
	return 0 unless $self && $corePath && $inputFile;

	# Now attempt to invoke the core.
	my $core = amampStartCore($corePath, $inputFile);
	if ($core) {
		# Success. Stash core object and return true.
		$self->{'core'} = $core;
		return 1;
	} else {
		# Failure.  Return false.
		return 0;
	}
}


# Gets a message in plain text. Essentially wraps the C function.
sub getRawMessage {
	# Get input.
	my ($self, $block) = @_;
	return undef unless $self;
	$block = 0+$block;

	# Attempt to call amampGetRawMessage and return what it gives.
	return amampGetRawMessage($self->{'core'}, $block);
}


# Sends a plain text message. Essentially wraps the C function.
sub sendRawMessage {
	# Get input.
	my ($self, $message) = @_;
	return 0 unless $message;

	# Attempt to call amampSendRawMessage and return what it gives.
	return amampSendRawMessage($self->{'core'}, $message);
}


# Sends a message arranged in a hash structure.
sub sendMessage {
	# Get input.
	my ($self, %input) = @_;
	return unless $input{'type'} && $input{'parameters'};

	# Construct message.
	my $message = "$input{'type'}:\n";
	for (keys %{$input{'parameters'}}) {
		$message .= "\t$_: $input{'parameters'}->{$_}\n";
	}
	$message .= "\n";
	
	# Attempt to send message.
	return $self->sendRawMessage($message);
}


# Gets a message and parses it into a hash based data structure.
sub getMessage {
	# Get input.
	my ($self, $block) = @_;
	return unless $self;

	# Get message.
	my $rawMessage = $self->getRawMessage($block);
	return () unless $rawMessage;

	# Parse.
	my $foundType = 0;
	my $line;
	my %message = ();
	my %params = ();
	foreach $line (split(/\n/, $rawMessage)) {
		if ($foundType) {
			# Should be a parameter.
			if ($line =~ /^\t([\w_\-]{1,30}): (.+)$/) {
				$params{$1} = $2;
			} elsif ($line ne '') {
				# Parse error.
				return ();
			}
		} else {
			# Should be type line.
			if ($line =~ /^([\w_\-]{1,30}):$/) {
				$message{'type'} = $1;
				$foundType = 1;
			} else {
				# Parse error.
				return ();
			}
		}
	}

	# Return message structure.
	$message{'parameters'} = \%params;
	return %message;
}


# This sub checks if the core is still alive/available.
sub isCoreAlive {
	# Just call C function to check.
	my ($self) = @_;
	return amampIsCoreAlive($self->{'core'});
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Audio::AMaMP - Perl language binding for the AMaMP Core

=head1 SYNOPSIS

  use Audio::AMaMP;

  # Start the core.
  $amamp = Audio::AMaMP->new;
  $amamp->startCore('/usr/bin/amamp', 'mymix.amamp');

  # Get a message.
  %message = $amamp->getMessage(1); # 1 = blocking, 0 = non-blocking
  print "Got message of type " . $message{'type'} . ".\n";

  # Send a message.
  $amamp->sendMessage(
      type        => 'core',
      parameters  =>
          {
	      request   => 'stop',
	      id        => '1234'
          }
  );

=head1 DESCRIPTION

This module provides a Perl language binding for the AMaMP cross-platform
audio engine. Capabilities include starting the eingine, sending messages
and receiving messages either in a blocking or a non-blocking fashion.
Messages can be sent and taken from the queue either in plain text or in
a hash based structure.

=head1 EXPORT

None by default.

=head1 METHODS

=item new

  $amamp = Audio::AMaMP->new;

Creates a new instance of the AMaMP core binding. Note that this call
alone does not start the core; you subsequently need to call startCore.

=item startCore

  $success = $amamp->startCore('/usr/bin/amamp', 'myinputfile.amamp;);

Attempts to start the AMaMP core executable (the location of which is
specified by the first parameter) with the input file specified by the
second parameter. It is acceptable to use relative paths for each of
these. Returns zero on failure or a non-zero value on success. Note
that just because you get a success return value doesn't mean all is
well - you need to monitor the message queue for any error messages.

=item sendMessage

  $success = $amamp->sendMessage(
      type        => 'core',
      parameters  =>
          {
	      request   => 'stop',
	      id        => '1234'
          }
  );

Sends a message to the core. Expects two named parameters. The first is
named type and is the type of the message to send (see IPC specification
for a list of valid types). The second is named parameters and is a
reference to a hash or parameters, where the key is the identifier and
the value is the data. Returns a non-zero message if the message is sent
and zero on error. Note that just because the message was sent does not
mean it is valid. If an invalid message is sent, the core will drop it
and send an invalid message warning.

=item sendRawMessage

  $success = $amamp->sendRawMessage($message);

Sends a message to the core. Takes a single parameter which is the
message, in plain text, to be sent. Returns a non-zero value if the
message was sent or zero if there was an error and it could not be
sent. Note that just because the message was sent does not mean it is
valid. If an invalid message is sent, the core will drop it and send
an invalid message warning.

=item getMessage

  %message = $amamp->getMessgae($block);

Attempts to get a message from the core. Takes a single parameter that
controls whether the call blocks. A value of zero will cause the method
to return immediately if there is no message. An empty hash will be
returned in this case. If there is a message, a message hash will be
returned which takes the same structure as that shown in sendMessage.
A non-zero value for block will only return an empty hash when an error
occurs, e.g. when the core has terminated. Otherwise, it will wait until
a message is available before returning.

=item getRawMessage

  $message = $amamp->getRawMessage($block);

Attempts to get a message from the core in plain text format. Takes a
single parameter that controls whether the call blocks. A value of zero
will call the method to return immediately if there is no message. undef
will be returned in this case. If there is a message, it will be returned
in plain text. A non-zero value for block will cause the method to only
return an undefined value when an error occurs, e.g. when the core has
terminated. Otherwise it will wait until a message is available before
returning.

=item isCoreAlive

  print "Core has not terminated" if $amamp->isCoreAlive;

Checks if the AMaMP core is still "alive", e.g. if it has terminated.
If it has terminated, 0 is returned. If it is still alive, a non-zero
value is returned. Note that just because the core is no longer alive
does not mean there are no messages left to read.

=head1 SEE ALSO

AMaMP has a website at L<http://amamp.sourceforge.net/>, which has
the latest news about the AMaMP core and its bindings as well as a
great deal of documentation about using the core, including its
instruction file and IPC message specification.

Comments, suggestions, bug reports or questions about this module
should be directed to the AMaMP development list. Information on
this list is on the site, and the address of the mailing list is
E<lt>amamp-development@lists.sourceforge.net<gt>.

=head1 AUTHOR

Jonathan Worthington, E<lt>jonathan@jwcs.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jonathan Worthington

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
