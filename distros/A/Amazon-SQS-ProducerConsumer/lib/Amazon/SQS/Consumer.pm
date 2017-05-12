package Amazon::SQS::Consumer;

use 5.006;
use strict;
use warnings;

use base 'Amazon::SQS::ProducerConsumer::Base';
use JSON::XS;
use Encode qw( encode_utf8 is_utf8 );

use constant {
	DEFAULT_N_MESSAGES => 10,
	DEFAULT_WAIT_SECONDS => 30,
	SECONDS_BETWEEN_TRIES => 10
};

=head1 NAME

Amazon::SQS::Consumer - Receive messages from an Amazon Simple Queue Service (SQS) queue

=cut

sub say (@) { warn join ' ', (split ' ', scalar localtime)[2,1,4,3], "[$$]", (split '/', $0)[-1], @_, "\n"; return @_; }
$SIG{INT} = sub { say 'caught signal INT'; exit 0; };
$SIG{CHLD} = 'IGNORE';

=head1 SYNOPSIS

  use Amazon::SQS::Consumer;

  my $in_queue = new Amazon::SQS::Consumer
    AWSAccessKeyId => 'PUBLIC_KEY_HERE',
    SecretAccessKey => 'SECRET_KEY_HERE',
    queue => 'YourInputQueue';

  while ( my $item = $in_queue->next ) {
    # Do stuff with the item
  }

=head1 METHODS

=head2 new(%params)

This is the constructor, it will return you an Amazon::SQS::Consumer object to work with.  It takes these parameters:

=over

=item AWSAccessKeyId (required)

Your AWS access key.

=item SecretAccessKey (required)

Your secret key, WARNING! don't give this out or someone will be able to use your account and incur charges on your behalf.

=item queue (required)

The URL of the queue to receive messages from.

=item wait_seconds (optional)

The number of seconds to wait for a new message when the queue is empty.

=item debug (optional)

A flag to turn on debugging. It is turned off by default.

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;

	my $me = \%args;
	bless $me, $class;
	$me->initialize;
	return $me;
}

sub initialize {
	my $me = shift;

	$me->{n_messages} ||= DEFAULT_N_MESSAGES;
	$me->{wait_seconds} ||= DEFAULT_WAIT_SECONDS;
	$me->SUPER::initialize;
}

=head2 next()

This will receive a message from this Publisher's queue. When the queue is empty it will wait a new message for wait_seconds seconds.

=cut

sub next {
	my $me = shift;

	# If we're done with the previous message, delete it
	$me->delete_previous();

	if ( @ARGV ) {
		$me->{messages} = [ map { MessageId => undef, Body => $_ }, @ARGV ];
		undef @ARGV;
		$me->{no_loop} = 't';
	}

	my $seconds_to_wait = $me->{wait_seconds};
	do {

		# If there no messages in the cache, get some from the queue
		$me->{messages} = $me->receive_messages(
			Queue => $me->{queue},
			MaxNumberOfMessages => $me->{n_messages},
			defined $me->{timeout} ? ( VisibilityTimeout => $me->{timeout} ) : ()
		) unless defined $me->{messages} && @{$me->{messages}} or $me->{no_loop};

		# If there's a message in the cache, return it
		if ( my $message = shift @{$me->{messages}} ) {
			$me->{DeleteMessageHandle} = $message->{ReceiptHandle};
			my $object;
			eval {
				my $body = $message->{Body};
				$body = encode_utf8( $body ) if is_utf8( $body );
				$object = decode_json $body;
			};
			if ( $@ ) {
				say "left bad message in queue; could not decode JSON from $message->{Body}: $@";
			} else {
				return $object;
			}
		} elsif ( $me->{no_loop} ) {
			$seconds_to_wait = 0;
		} else {
			# Otherwise, wait a few seconds and try again
			say "waiting $seconds_to_wait seconds for new messages"
				if $seconds_to_wait == $me->{wait_seconds};
			sleep SECONDS_BETWEEN_TRIES;
			$seconds_to_wait -= SECONDS_BETWEEN_TRIES;
		}

	} while ( $me->{forever} or $seconds_to_wait > 0 );

	# If we've retried for a while and gotten no messages, give up
	return undef;

}

sub delete_previous {
	my $me = shift;

	if ( $me->{DeleteMessageHandle} ) {
		say "deleting message $me->{DeleteMessageHandle}" if $me->{debug};
		$me->delete_message( Queue => $me->{queue}, ReceiptHandle => $me->{DeleteMessageHandle} );
	}
}

sub defer { delete $_[0]->{DeleteMessageHandle} }


=head1 AUTHOR

Nic Wolff, <nic@angel.net>

=head1 BUGS

Please report any bugs or feature requests to C<bug-amazon-sqs-producerconsumer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amazon-SQS-ProducerConsumer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Amazon::SQS::ProducerConsumer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Amazon-SQS-ProducerConsumer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Amazon-SQS-ProducerConsumer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Amazon-SQS-ProducerConsumer>

=item * Search CPAN

L<http://search.cpan.org/dist/Amazon-SQS-ProducerConsumer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Nic Wolff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Amazon::SQS::ProducerConsumer
