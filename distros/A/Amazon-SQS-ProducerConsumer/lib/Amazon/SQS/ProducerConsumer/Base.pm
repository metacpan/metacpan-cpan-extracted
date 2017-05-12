package Amazon::SQS::ProducerConsumer::Base;

use 5.006;
use strict;
use warnings;

use XML::Simple;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use URI::Escape qw(uri_escape_utf8);
use MIME::Base64 qw(encode_base64);


=head1 NAME

Amazon::SQS::ProducerConsumer::Base - Perl interface to the Amazon Simple Queue Service (SQS) environment

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

 use Amazon::SQS::ProducerConsumer::Base;

 my $sqs = new Amazon::SQS::ProducerConsumer::Base
	AWSAccessKeyId => 'PUBLIC_KEY_HERE',
	SecretAccessKey => 'SECRET_KEY_HERE';

 # Create a queue
 my $queueURL = $sqs->create_queue( QueueName => 'TestQueue' );

 # Send a message to that queue
 my $messageID = $sqs->send_message( Queue => $queueURL, MessageBody => 'Test message' );

 # Get a message from that queue
 my $message = $sqs->receive_message( Queue => $queueURL );
 print 'Message ID: ', $message->{MessageId}, "\n";
 print 'Message: ', $message->{MessageBody}, "\n";

 # Delete the message you got
 my $message = $sqs->delete_message( Queue => $queueURL, MessageId => $message->{MessageId} );

If an error occurs in communicating with SQS, the return value will be undef and $sqs->{error} will be populated with the message.

=cut

sub new {
	my ($class, %args) = @_;

	my $me = \%args;
	bless $me, $class;
	$me->initialize;
	return $me;
}

sub initialize {
	my $me = shift;
	$me->{signature_version} = 2;
	$me->{version} = '2009-02-01';
	$me->{host} ||= 'queue.amazonaws.com';
}

sub create_queue {
	my ($me, %args) = @_;

	my $xml = $me->sign_and_post( Action => 'CreateQueue', %args );
	return undef if $me->check_error( $xml );
	return $xml->{CreateQueueResult}{QueueUrl};
}

sub list_queues {
	my ($me, %args) = @_;

	my $xml = $me->sign_and_post( Action => 'ListQueues', %args );
	return undef if $me->check_error( $xml );

	my $result;
	$result = $xml->{ListQueuesResult}{QueueUrl};
	map { $_ = (split '/', $_)[-1] } @$result if ref $result eq 'ARRAY';
	return ref $result eq 'ARRAY' ? @$result : $result;
}

sub delete_queue {
	my ($me, %args) = @_;

	delete $args{ForceDeletion};
	my $xml = $me->sign_and_post( Action => 'DeleteQueue', %args );
	return undef if $me->check_error( $xml );

	return $xml->{ResponseMetadata}{RequestId};
}

sub send_message {
	my ($me, %args) = @_;

	my $xml = $me->sign_and_post( Action => 'SendMessage', %args );
	return undef if $me->check_error( $xml );

	return $xml->{SendMessageResult}{MessageId};
}

sub receive_message {
	my ($me, %args) = @_;

	delete $args{NumberOfMessages};
	my $xml = $me->sign_and_post( Action => 'ReceiveMessage', %args );
	return undef if $me->check_error( $xml );

	return $xml->{ReceiveMessageResult}{Message};
}

sub receive_messages {
	my ($me, %args) = @_;

	my $xml = $me->sign_and_post( Action => 'ReceiveMessage', %args );
	return undef if $me->check_error( $xml );
	my $result = $xml->{ReceiveMessageResult}{Message};
	return ref $result eq 'ARRAY' ? $result : [ $result ];
}

sub delete_message {
	my ($me, %args) = @_;

	my $xml = $me->sign_and_post( Action => 'DeleteMessage', %args );
	return undef if $me->check_error( $xml );
	return $xml->{ResponseMetadata}{RequestId};
}

sub get_queue_attributes {
	my ($me, %args) = @_;

	my $xml = $me->sign_and_post( Action => 'GetQueueAttributes', %args );
	return undef if $me->check_error( $xml );
	return $xml->{GetQueueAttributesResult}{Attribute}[0]{Value};
}

sub set_queue_attributes {
	my ($me, %args) = @_;

	my $xml = $me->sign_and_post( Action => 'SetQueueAttributes', %args );
	return undef if $me->check_error( $xml );
	return $xml->{ResponseMetadata}{RequestId};
}

sub sign_and_post {
	my ($me, %args) = @_;

	$me->{resource_path} = join '/', '', grep $_, $args{AWSAccessKeyId}, delete $args{Queue} if exists $args{Queue};
	$me->{resource_path} ||= '/';

	my @t = gmtime;

	$args{AWSAccessKeyId} = $me->{AWSAccessKeyId};
	$args{SignatureVersion} = $me->{signature_version};
	$args{SignatureMethod} = 'HmacSHA1';
	$args{Version} = $me->{version};
	$args{Timestamp} = sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ", $t[5]+1900, $t[4]+1, @t[3,2,1,0];
	$args{MaxNumberOfMessages} = delete $args{NumberOfMessages} if $args{NumberOfMessages};

	my @params;
	for ( sort keys %args ) {
		push @params, join '=', $_, uri_escape_utf8( $args{$_}, "^A-Za-z0-9\-_.~" );
	}

	$me->{resource_path} =~ s|http://$me->{host}/||;
	my $string_to_sign = join( "\n",
                'POST', $me->{host}, $me->{resource_path}, join( '&', @params )
        );

	$me->debug("QUERY TO SIGN: $string_to_sign");

	my $hashed = Digest::HMAC_SHA1->new( $me->{SecretAccessKey} );
	$hashed->add( $string_to_sign );
	my $encoded = encode_base64( $hashed->digest, '' );
	$me->debug("ENCODED SIGNATURE: $encoded");
	$args{Signature} = $encoded;

	my $result = LWP::UserAgent->new->post( "http://$me->{host}$me->{resource_path}", \%args );

	$me->debug("REQUEST RETURNED: " . $result->content);

	if ( $result->is_success ) {
		my $parser = XML::Simple->new( ForceArray => [ 'item', 'QueueURL','AttributedValue', 'Attribute' ] );
		return $parser->XMLin( $result->content() );
	} else {
		return { Errors => { Error => { Message => 'HTTP POST failed with error ' . $result->status_line } } };
	}

}

sub check_error {
	my ($me, $xml) = @_;

	if ( defined $xml->{Errors} && defined $xml->{Errors}{Error} ) {
		$me->debug("ERROR: $xml->{Errors}{Error}{Message}");
		$me->{error} = $xml->{Errors}{Error}{Message};
		warn $me->{error};
		return 1;
	}
}

sub error { $_[0]->{error} }

sub debug {
	my ($me, $message) = @_;

	if ((grep { defined && length } $me->{debug}) && $me->{debug} == 1) {
		warn "$message\n";
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

    perldoc Amazon::SQS::ProducerConsumer::Base


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

1;
