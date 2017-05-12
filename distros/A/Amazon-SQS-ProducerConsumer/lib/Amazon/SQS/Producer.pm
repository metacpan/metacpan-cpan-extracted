package Amazon::SQS::Producer;

use 5.006;
use strict;
use warnings;

use base 'Amazon::SQS::ProducerConsumer::Base';
use JSON::XS;

use constant MAX_RETRIES => 3;

=head1 NAME

Amazon::SQS::Producer - Publish messages to an Amazon Simple Queue Service (SQS) queue

=cut

sub say (@) { warn join ' ', (split ' ', scalar localtime)[2,1,4,3], "[$$]", (split '/', $0)[-1], @_, "\n"; return @_; }
$SIG{INT} = sub { say 'caught signal INT'; exit 0; };
$SIG{CHLD} = 'IGNORE';

=head1 SYNOPSIS

  use Amazon::SQS::Producer;

  my $out_queue = new Amazon::SQS::Producer
    AWSAccessKeyId => 'PUBLIC_KEY_HERE',
    SecretAccessKey => 'SECRET_KEY_HERE',
    queue => 'YourOutputQueue',
    consumer => 'ConsumerForOutputQueue';

  $out_queue->publish(
    $existingObjectRef,
    url => $enclosure_URL,
    pubdate => $pubDate,
    title => $title,
    description => $description,
    rss_guid => $guid,
  );

=head1 METHODS

=head2 new(%params)

This is the constructor, it will return you an Amazon::SQS::Producer object to work with.  It takes these parameters:

=over

=item AWSAccessKeyId (required)

Your AWS access key.

=item SecretAccessKey (required)

Your secret key, WARNING! don't give this out or someone will be able to use your account and incur charges on your behalf.

=item queue (required)

The URL of the queue to publish messages to.

=item consumer (optional)

The name of an executable that will consume messages from the queue we're publishing to. An instance will be launched after the each message is published, up to the maximum set by...

=item start_consumers (optional)

The maximum number of consumer instance to launch.

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

	$me->{sleep_after_starting_consumer} = 2 if not exists $me->{sleep_after_starting_consumer};
	$me->SUPER::initialize;
}

=head2 publish(%params)

This will publish a message to this Publisher's queue, and start a consumer if this is the first message this Publisher has published. The message body will be a JSON representaton of the method's argument hash. If the first argument is a reference to a hash it will be dereferenced and merged with the other parameters given.

=cut

sub publish {
	if ( ref $_[0] and ! $_[0]->{queue} ) { goto &fork_consumer }
	if ( ref $_[1] and $_[1]->{_chain_consumers} ) { goto &fork_consumer }

	my $me = shift;
	my $old_data = shift if ref $_[0];
	my $data = { %$old_data, @_ };
	my $encoded_data = encode_json $data;

	say "Queueing message: $encoded_data" if $data->{_debug};
	return if $data->{_test};

	my $retries;
	my $message_id;
	until (
		$message_id = $me->send_message(
			Queue => $me->{queue},
			MessageBody => $encoded_data,
		)
	) {
		say "couldn't queue message: ", $me->error;
		if ( $retries++ < MAX_RETRIES ) {
			say "trying again in $retries seconds";
			sleep $retries;
		} else {
			say "giving up trying to publish to queue $me->{queue} with message body: $encoded_data",
			return;
		}
	}

	if ( $me->{consumer} and $me->{started_consumers}++ < $me->{start_consumers} ) {
		my $pid = fork;
		if ( not defined $pid ) {
			say "couldn't fork";
		} elsif ( not $pid ) {
			close STDIN; open STDIN, '/dev/null';
			close STDOUT; open STDOUT, '/dev/null';
			close STDERR; open STDERR, '>>/tmp/getfeeds.log';
			sleep $me->{sleep_after_starting_consumer};
			exec $me->{consumer};
		} else {
			say "started consumer $me->{consumer} with PID $pid for queue $me->{queue}";
		}
	}

	return $message_id;

}

sub fork_and_publish {
	my $me = shift;

	my $pid = fork;
	if ( not defined $pid ) {
		say "couldn't fork";
	} elsif ( not $pid ) {
		$me->publish( @_ );
	} else {
		say "forked to publish to queue $me->{queue} with PID $pid";
	}
}

sub fork_consumer {
	my $me = shift;
	my $old_data = shift if ref $_[0];
	my %data = @_;

	if ( $me->{consumer} ) {
		my $pid = fork;
		if ( not defined $pid ) {
			say "couldn't fork";
		} elsif ( not $pid ) {
			close STDIN; open STDIN, '/dev/null';
			close STDOUT; open STDOUT, '/dev/null';
			close STDERR; open STDERR, '>>/tmp/getfeeds.log';
			$ENV{PATH} .= ':.';
			sleep $me->{sleep_after_starting_consumer};
			exec $me->{consumer}, encode_json { %$old_data, %data };
		} else {
			say "forked consumer $me->{consumer} with PID $pid";
		}
	}
}

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
