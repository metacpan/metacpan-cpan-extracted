package Amazon::SQS::Simple::Queue;

use strict;
use warnings;
use Amazon::SQS::Simple::Message;
use Amazon::SQS::Simple::SendResponse;
use Carp qw( croak carp );

use base 'Amazon::SQS::Simple::Base';
use Amazon::SQS::Simple::Base; # for constants

use overload '""' => \&_to_string;

sub Endpoint {
    my $self = shift;
    return $self->{Endpoint};
}

sub Delete {
    my $self = shift;
    my $params = { Action => 'DeleteQueue' };
    
    my $href = $self->_dispatch($params);    
}

sub Purge {
    my $self = shift;
    my $params = { Action => 'PurgeQueue' };
    
    my $href = $self->_dispatch($params);    
}

sub SendMessage {
    my ($self, $message, %params) = @_;
    
    $params{Action} = 'SendMessage';
    $params{MessageBody} = $message;
    
    my $href = $self->_dispatch(\%params);    

    # default to most recent version
    return new Amazon::SQS::Simple::SendResponse(
        $href->{SendMessageResult}, $message
    );
}

sub SendMessageBatch {
    my ($self, $messages, %params) = @_;
    
    $params{Action} = 'SendMessageBatch';
    
    if (ref($messages) eq  'ARRAY'){
        my %messages;
        my @IDs = map { "msg_$_" } (1..scalar(@$messages));
        @messages{@IDs} = @$messages;
        $messages = \%messages;
    }
    
    my $i=0;
    while (my ($id, $msg) = each %$messages){
        if ($i==10){
            warn "Batch messaging limited to 10 messages";
            last;
        }
        $i++;
        $params{"SendMessageBatchRequestEntry.$i.Id"} = $id;
        $params{"SendMessageBatchRequestEntry.$i.MessageBody"} = $msg;
    }
    
    my $href = $self->_dispatch(\%params, [qw/SendMessageBatchResultEntry/]); 
    my @responses = ();
    
    # default to most recent version
    for (@{$href->{SendMessageBatchResult}{SendMessageBatchResultEntry}}) {
        push @responses, new Amazon::SQS::Simple::SendResponse($_, $messages->{$_->{Id}});
    }
    
    if (wantarray){
        return @responses;
    }
    else {
        return \@responses;
    }
}

sub ReceiveMessage {
    my ($self, %params) = @_;
    
    $params{Action} = 'ReceiveMessage';
    
    my $href = $self->_dispatch(\%params, [qw(Message)]);

    my @messages = ();

    # default to most recent version
    if (defined $href->{ReceiveMessageResult}{Message}) {
        foreach (@{$href->{ReceiveMessageResult}{Message}}) {
            push @messages, new Amazon::SQS::Simple::Message(
                $_,
                $self->_api_version()
            );
        }
    }
    
    if (wantarray) {
        return @messages;
    } 
    elsif (@messages) {
        return $messages[0];
    } 
    else {
        return undef;
    }
}

sub ReceiveMessageBatch {
    my ($self, %params) = @_;
    $params{MaxNumberOfMessages} = 10;
    $self->ReceiveMessage(%params);
}

sub DeleteMessage {
    my ($self, $message, %params) = @_;
    
    # to be consistent with DeleteMessageBatch, this will now accept a message object
    my $receipt_handle;
    if (ref($message) && $message->isa('Amazon::SQS::Simple::Message')){
        $receipt_handle = $message->ReceiptHandle;
    }
    # for backward compatibility, we will still cope with a receipt handle
    else {
        $receipt_handle = $message;
    }
    $params{Action} = 'DeleteMessage';
    $params{ReceiptHandle} = $receipt_handle;
    
    my $href = $self->_dispatch(\%params);
}

sub DeleteMessageBatch {
    my ($self, $messages, %params) = @_;
    return unless @$messages;
    $params{Action} = 'DeleteMessageBatch';
    
    my $i=0;
    foreach my $msg (@$messages){
        $i++;
        if ($i>10){
            warn "Batch deletion limited to 10 messages";
            last;
        }
        
        $params{"DeleteMessageBatchRequestEntry.$i.Id"} = $msg->MessageId;
        $params{"DeleteMessageBatchRequestEntry.$i.ReceiptHandle"} = $msg->ReceiptHandle;
    }
    
    my $href = $self->_dispatch(\%params);
}

sub ChangeMessageVisibility {
    my ($self, $receipt_handle, $timeout, %params) = @_;
    
    if (!defined($timeout) || $timeout =~ /\D/ || $timeout < 0 || $timeout > 43200) {
        croak "timeout must be specified and in range 0..43200";
    }
    
    $params{Action}             = 'ChangeMessageVisibility';
    $params{ReceiptHandle}      = $receipt_handle;
    $params{VisibilityTimeout}  = $timeout;
    
    my $href = $self->_dispatch(\%params);
}

our %valid_permission_actions = map { $_ => 1 } qw(* SendMessage ReceiveMessage DeleteMessage ChangeMessageVisibility GetQueueAttributes);

sub AddPermission {
    my ($self, $label, $account_actions, %params) = @_;
    
    $params{Action} = 'AddPermission';
    $params{Label}  = $label;
    my $i = 1;
    foreach my $account_id (keys %$account_actions) {
        $account_id =~ /^\d{12}$/ or croak "Account IDs passed to AddPermission should be 12 digit AWS account numbers, no hyphens";
        my $actions = $account_actions->{$account_id};
        my @actions;
        if (UNIVERSAL::isa($actions, 'ARRAY')) {
            @actions = @$actions;
        } else {
            @actions = ($actions);
        }
        foreach my $action (@actions) {
            exists $valid_permission_actions{$action} 
                or croak "Action passed to AddPermission must be one of " 
                . join(', ', sort keys %valid_permission_actions);
            
            $params{"AWSAccountId.$i"} = $account_id;
            $params{"ActionName.$i"}   = $action;
            $i++;
        }
    }
    my $href = $self->_dispatch(\%params);
}

sub RemovePermission {
    my ($self, $label, %params) = @_;
        
    $params{Action} = 'RemovePermission';
    $params{Label}  = $label;
    my $href = $self->_dispatch(\%params);
}

sub GetAttributes {
    my ($self, %params) = @_;
    
    $params{Action} = 'GetQueueAttributes';

    my %result;
    # default to the current version
    $params{AttributeName} ||= 'All';

    my $href = $self->_dispatch(\%params, [ 'Attribute' ]);

    if ($href->{GetQueueAttributesResult}) {
        foreach my $attr (@{$href->{GetQueueAttributesResult}{Attribute}}) {
            $result{$attr->{Name}} = $attr->{Value};
        }
    }
    return \%result;
}

sub SetAttribute {
    my ($self, $key, $value, %params) = @_;
    
    $params{Action}             = 'SetQueueAttributes';
    $params{'Attribute.Name'}   = $key;
    $params{'Attribute.Value'}  = $value;
    
    my $href = $self->_dispatch(\%params);
}

sub _to_string {
    my $self = shift;
    return $self->Endpoint();
}

1;

__END__

=head1 NAME

Amazon::SQS::Simple::Queue - OO API for representing queues from 
the Amazon Simple Queue Service.

=head1 SYNOPSIS

    use Amazon::SQS::Simple;

    my $access_key = 'foo'; # Your AWS Access Key ID
    my $secret_key = 'bar'; # Your AWS Secret Key

    my $sqs = new Amazon::SQS::Simple($access_key, $secret_key);

    my $q = $sqs->CreateQueue('queue_name');

    # Single messages
    
    my $response = $q->SendMessage('Hello world!');
    my $msg = $q->ReceiveMessage;
    print $msg->MessageBody; # Hello world!    
    $q->DeleteMessage($msg);
    # or, for backward compatibility
    $q->DeleteMessage($msg->ReceiptHandle);
    
    # Batch messaging of up to 10 messages per operation
    
    my @responses = $q->SendMessageBatch( [ 'Hello world!', 'Hello again!' ] );    
    # or with defined message IDs
    $q->SendMessageBatch( { msg1 => 'Hello world!', msg2 => 'Hello again!' } );
    my @messages = $q->ReceiveMessageBatch; 
    $q->DeleteMessageBatch( \@messages );

=head1 INTRODUCTION

Don't instantiate this class directly. Objects of this class are returned
by various methods in C<Amazon::SQS::Simple>. See L<Amazon::SQS::Simple> for
more details.

=head1 METHODS

=over 2

=item B<Endpoint()>

Get the endpoint for the queue.

=item B<Delete([%opts])>
 
Deletes the queue. Any messages contained in the queue will be lost.

=item B<Purge>

Purges the queue.

=item B<SendMessage($message, [%opts])>

Sends the message. The message can be up to 8KB in size and should be
plain text.

=item B<SendMessageBatch($messages, [%opts])>

Sends a batch of up to 10 messages, passed as an array-ref. 
Message IDs (of the style 'msg_1', 'msg_2', etc) are auto-generated for each message.
Alternatively, if you need to specify the format of the message ID then you can pass a hash-ref {$id1 => $message1, etc}

=item B<ReceiveMessage([%opts])>

Get the next message from the queue.

Returns one or more C<Amazon::SQS::Simple::Message> objects (depending on whether called in list or scalar context), 
or undef if no messages are retrieved. 

NOTE: This behaviour has changed slightly since v1.06. It now always returns the first message in scalar
context, irrespective of how many there are.

See L<Amazon::SQS::Simple::Message> for more details.

Options for ReceiveMessage:

=over 4

=item * MaxNumberOfMessages => INTEGER

Maximum number of messages to return (integer from 1 to 20). SQS never returns more messages than this value but might 
return fewer. Not necessarily all the messages in the queue are returned. Defaults to 1.

=item * WaitTimeSeconds => INTEGER

Long poll support (integer from 0 to 20). The duration (in seconds) that the I<ReceiveMessage> action call will wait 
until a message is in the queue to include in the response, as opposed to returning an empty response if a message 
is not yet available.

If you do not specify I<WaitTimeSeconds> in the request, the queue attribute I<ReceiveMessageWaitTimeSeconds>
is used to determine how long to wait.

=item * VisibilityTimeout => INTEGER

The duration in seconds (integer from 0 to 43200) that the received messages are hidden from subsequent retrieve 
requests after being retrieved by a I<ReceiveMessage> request.

If you do not specify I<VisibilityTimeout> in the request, the queue attribute I<VisibilityTimeout> is used to 
determine how long to wait.

=back

=item B<ReceiveMessageBatch([%opts])>

As ReceiveMessage(MaxNumberOfMessages => 10)

=item B<DeleteMessage($message, [%opts])>

Pass this method either a message object or receipt handle to delete that message from the queue. 
For backward compatibility, can pass the message ReceiptHandle rather than the message. 

=item B<DeleteMessageBatch($messages, [%opts])>

Pass this method an array-ref containing up to 10 message objects to delete all of those messages from the queue

=item B<ChangeMessageVisibility($receipt_handle, $timeout, [%opts])>

NOT SUPPORTED IN APIs EARLIER THAN 2009-01-01

Changes the visibility of the message with the specified receipt handle to
C<$timeout> seconds. C<$timeout> must be in the range 0..43200.

=item B<AddPermission($label, $account_actions, [%opts])>

NOT SUPPORTED IN APIs EARLIER THAN 2009-01-01

Sets a permissions policy with the specified label. C<$account_actions>
is a reference to a hash mapping 12-digit AWS account numbers to the action(s)
you want to permit for those account IDs. The hash value for each key can 
be a string (e.g. "ReceiveMessage") or a reference to an array of strings 
(e.g. ["ReceiveMessage", "DeleteMessage"])

=item B<RemovePermission($label, [%opts])>

NOT SUPPORTED IN APIs EARLIER THAN 2009-01-01

Removes the permissions policy with the specified label.

=item B<GetAttributes([%opts])>

Get the attributes for the queue. Returns a reference to a hash
mapping attribute names to their values. Currently the following
attribute names are returned:

=over 4

=item * VisibilityTimeout

=item * ApproximateNumberOfMessages

=back

=item B<SetAttribute($attribute_name, $attribute_value, [%opts])>

Sets the value for a queue attribute. Currently the only valid
attribute name is C<VisibilityTimeout>.

=back

=head1 ACKNOWLEDGEMENTS

Chris Jones provied the batch message code in release 2.0

=head1 AUTHOR

Copyright 2007-2008 Simon Whitaker E<lt>swhitaker@cpan.orgE<gt>
Copyright 2013-2017 Mike (no relation) Whitaker E<lt>penfold@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
