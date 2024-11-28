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


package Amazon::SQS::Model::CreateQueueRequest;

use base qw (Amazon::SQS::Model);

=pod

=head1 NAME

 Amazon::SQS::Model::CreateQueueRequest

=head1 SYNOPSIS

 my $request = new Amazon::SQS::Model::CreateQueueRequest(
                                                          {
                                                           QueueName => $queue_name,
                                                           DefaultVisibilityTime => $timeout
                                                          }
                                                         );

 $service->createQueue( $request );

=head1 DESCRIPTION

Implements a class that represents a request used to create a new SQS
queue.

=head1 METHODS

=head2 new

 new( options ) 

=over 5

=item options

Hash reference containing the options listed below.

=over 5

=item QueueName

The name of the queue that you created.

=item DefaultVisibilityTimeout

The amount of time (in seconds) that a message received from a queue
will be I<invisible> to other receiving components when they ask to
receive messages.

=item Attribute

C<Amazon::SQS::Model::Attribute>

=back

=back

=cut
    

sub new {
  my ($class, $data) = @_;
  my $self = {};
  $self->{_fields} = {
		      QueueName => { FieldValue => undef, FieldType => "string"},
		      DefaultVisibilityTimeout => { FieldValue => undef, FieldType => "int"},
		      Attribute => {FieldValue => [], FieldType => ["Amazon::SQS::Model::Attribute"]},
		     };

  bless ($self, $class);
  if (defined $data) {
    $self->_fromHashRef($data); 
  }
        
  return $self;
}

    
sub getQueueName {
  return shift->{_fields}->{QueueName}->{FieldValue};
}


sub setQueueName {
  my ($self, $value) = @_;

  $self->{_fields}->{QueueName}->{FieldValue} = $value;
  return $self;
}


sub withQueueName {
  my ($self, $value) = @_;
  $self->setQueueName($value);
  return $self;
}


sub isSetQueueName {
  return defined (shift->{_fields}->{QueueName}->{FieldValue});
}


sub getDefaultVisibilityTimeout {
  return shift->{_fields}->{DefaultVisibilityTimeout}->{FieldValue};
}


sub setDefaultVisibilityTimeout {
  my ($self, $value) = @_;

  $self->{_fields}->{DefaultVisibilityTimeout}->{FieldValue} = $value;
  return $self;
}


sub withDefaultVisibilityTimeout {
  my ($self, $value) = @_;
  $self->setDefaultVisibilityTimeout($value);
  return $self;
}


sub isSetDefaultVisibilityTimeout {
  return defined (shift->{_fields}->{DefaultVisibilityTimeout}->{FieldValue});
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

=head1 SEE ALSO

C<Amazon::SQS::Client>

=head1 AUTHOR

Elena@AWS

=cut

1;
