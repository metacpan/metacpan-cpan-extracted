################################################################################ 
#  Copyright 2008 Amazon Technologies, Inc.
#  Licensed under the Apache License, Version 2.0 (the "License"); 
#  
#  You may not use this file except in compliance with the License. 
#  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
#  CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#  specific language governing permissions and limitations under the License.
################################################################################ 
#    __  _    _  ___ 
#   (  )( \/\/ )/ __)
#   /__\ \    / \__ \
#  (_)(_) \/\/  (___/
# 
#  Amazon SQS Perl Library
#  API Version: 2009-02-01
#  Generated: Thu Apr 09 01:13:11 PDT 2009 
# 


package Amazon::SQS::Model::ListQueuesRequest;

use base qw (Amazon::SQS::Model);

=pod

=head1 NAME

 Amazon::SQS::Model::ListQueuesRequest

=head1 SYNOPSIS

 my $request = new Amazon::SQS::Model::ListQueuesRequest(
                                                         {
                                                          QueueNamePrefix => 'some-prefix'
                                                         }
                                                        );

=head1 DESCRIPTION

The ListQueues action returns a list of your queues. The maximum
number of queues that can be returned is 1000. If you specify a value
for the optional C<QueueNamePrefix> parameter, only queues with a name
beginning with the specified value are returned.

=head1 METHODS

=head2 new

 new( options )

=over 5

=item QueueNamePrefix

String to use for filtering the list results. Only those queues whose
name begins with the specified string are returned.

=item Attribute

C<Amazon::SQS::Model::Attribute>

This is undocumented on AmazonE<039>s documentation page, however this
perl API apparently sends the attributes implying that you might be
able to list all queues that have a prefix of "some-prefix" AND have
some attribute.

Queue attributes are set when the queue is created and are listed below.

=over 5

=item * VisibilityTimeout

The length of time (in seconds) that a message
received from a queue will be invisible to other receiving components
when they ask to receive messages. For more information about
VisibilityTimeout, see Visibility Timeout in the Amazon SQS Developer
Guide.

=item * Policy

The formal description of the permissions for a resource. For more
information about Policy, see Basic Policy Structure in the Amazon SQS
Developer Guide.

=item * MaximumMessageSize

The limit of how many bytes a message can contain before Amazon SQS rejects it.

=item * MessageRetentionPeriod

The number of seconds Amazon SQS retains a message.

=item * DelaySeconds

The time in seconds that the delivery of all messages in the queue
will be delayed.

=back

=back

=cut
    

sub new {
  my ($class, $data) = @_;

  my $self = {};

  $self->{_fields} = {
		      QueueNamePrefix => { FieldValue => undef, FieldType => "string"},
		      Attribute => {FieldValue => [], FieldType => ["Amazon::SQS::Model::Attribute"]},
		     };
  
  bless ($self, $class);

  if (defined $data) {
    $self->_fromHashRef($data); 
  }
        
  return $self;
}

    
sub getQueueNamePrefix {
  return shift->{_fields}->{QueueNamePrefix}->{FieldValue};
}


sub setQueueNamePrefix {
  my ($self, $value) = @_;

  $self->{_fields}->{QueueNamePrefix}->{FieldValue} = $value;
  return $self;
}


sub withQueueNamePrefix {
  my ($self, $value) = @_;
  $self->setQueueNamePrefix($value);
  return $self;
}


sub isSetQueueNamePrefix {
  return defined (shift->{_fields}->{QueueNamePrefix}->{FieldValue});
}

sub getAttribute {
  return shift->{_fields}->{Attribute}->{FieldValue};
}

sub setAttribute {
  my $self = shift;
  foreach my $attribute (@_) {
    if (not $self->_isArrayRef($attribute)) {
      $attribute =  [$attribute];    
    }
    $self->{_fields}->{Attribute}->{FieldValue} = $attribute;
  }
}

sub withAttribute {
  my ($self, $attributeArgs) = @_;
  foreach my $attribute (@$attributeArgs) {
    $self->{_fields}->{Attribute}->{FieldValue} = $attribute;
  }
  return $self;
}   


sub isSetAttribute {
  return  scalar (@{shift->{_fields}->{Attribute}->{FieldValue}}) > 0;
}

=pod

=head1 SEE OTHER

C<Amazon::SQS::Client>

=head1 AUTHOR

Elena@AWS

=cut

1;
