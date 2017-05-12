package Data::AMF::Remoting;
use strict;
use warnings;

use Data::AMF::Message;
use Data::AMF::Packet;

use constant CLIENT_PING_OPERATION => 5;
use constant COMMAND_MESSAGE       => 'flex.messaging.messages.CommandMessage';
use constant REMOTING_MESSAGE      => 'flex.messaging.messages.RemotingMessage';
use constant ACKNOWLEDGE_MESSAGE   => 'flex.messaging.messages.AcknowledgeMessage';

sub new {
	my $class = shift;	
	my $self = bless {
		source => undef,
		data => undef,
		headers_did_process => sub {},
		message_did_process => sub {},
		@_,
	}, $class;

	if (ref $self->{headers_handler} eq 'CODE') {
		$self->{headers_did_process} = $self->{headers_handler};
	}

	if (ref $self->{message_handler} eq 'CODE') {
		$self->{message_did_process} = $self->{message_handler};
	}

	return $self;
}

sub data { $_[0]->{'data'} }

sub run {
	my $self = shift;
	
	my $request = Data::AMF::Packet->deserialize($self->{'source'});
	
	my @headers = @{ $request->headers };
	@headers = $self->{'headers_did_process'}->(@headers);
	
	my @messages;
	
	for my $message (@{ $request->messages }) {
		my $target_uri = $message->target_uri;
		
		# RemoteObject
		if (not defined $target_uri or $target_uri eq 'null') {	
			my $type      = $message->value->[0]->{'_explicitType'};
			my $source    = $message->value->[0]->{'source'};
			my $operation = $message->value->[0]->{'operation'};
			
			if ($type eq COMMAND_MESSAGE and $operation eq CLIENT_PING_OPERATION) {
				push @messages, $message->result($message->value->[0]);
			}
			elsif ($type eq REMOTING_MESSAGE) {
				$target_uri = '';
				
				if (defined $source and $source ne '') {
					$target_uri .= $source . '.';
				}
				
				if (defined $operation and $operation ne '') {
					$target_uri .= $operation;
				}
				
				my $res = $self->{'message_did_process'}->(
					Data::AMF::Message->new(
						target_uri   => $target_uri,
						response_uri => '',
						value        => $message->value->[0]->{'body'}
					)
				);
				
				push @messages, $message->result({
					correlationId => $message->value->[0]->{'messageId'},
					messageId     => undef,
					clientId      => undef,
					destination   => '',
					timeToLive    => 0,
					timestamp     => 0,
					body          => $res,
					headers       => {},
					_explicitType => ACKNOWLEDGE_MESSAGE,
				});
			}		
			else {
				die "Recived unsupported message.";
			}
		}
		# Net Connection
		else {			
			my $res = $self->{'message_did_process'}->($message);
			push @messages, $message->result($res);
		}
	}
	
	my $response = Data::AMF::Packet->new(
		version  => $request->version,
		headers  => \@headers,
		messages => \@messages,
	);
	
	$self->{'data'}  = $response->serialize;
	
	return $self;
}

1;

__END__

=head1 NAME
 
Data::AMF::Remoting - handle Flash/Flex RPC.

=head1 SYNOPSIS

    use Data::AMF::Remoting

    my $remoting = Data::AMF::Remoting->new(
        source => $data,
        headers_handler => sub
        {
            my @headers = @_;

            # Do authenticate or something.

            return @headers;
        },
        message_handler => sub
        {
            my $message = shift;

            # Call action using target_uri and value.

            my ($controller_name, $action) = split '\.', $message->target_uri;

            $controller_name->require;
            my $controller = $controller_name->new;

            return $controller->$action($message->value);
        }
    );
    $remoting->run;

    my $data = $remoting->data;

=head1 DESCRIPTION

Data::AMF::Remoting provides to handle Flash/Flex RPC.

=head1 SEE ALSO

L<Data::AMF>

=head1 METHODS

=head2 run

Handle AMF Packet data.

=head1 ACCESSORS

=head2 data

return AMF Data

=head1 AUTHOR

Takuho Yoshizu <seagirl@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
