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


package Amazon::SQS::Model::GetQueueAttributesRequest;

use base qw (Amazon::SQS::Model);

    

    #
    # Amazon::SQS::Model::GetQueueAttributesRequest
    # 
    # Properties:
    #
    # 
    # QueueUrl: string
    # AttributeName: string
    #
    # 
    # 
    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {
            
            QueueUrl => { FieldValue => undef, FieldType => "string"},
            AttributeName => {FieldValue => [], FieldType => ["string"]},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data); 
        }
        
        return $self;
    }

    
    sub getQueueUrl {
        return shift->{_fields}->{QueueUrl}->{FieldValue};
    }


    sub setQueueUrl {
        my ($self, $value) = @_;

        $self->{_fields}->{QueueUrl}->{FieldValue} = $value;
        return $self;
    }


    sub withQueueUrl {
        my ($self, $value) = @_;
        $self->setQueueUrl($value);
        return $self;
    }


    sub isSetQueueUrl {
        return defined (shift->{_fields}->{QueueUrl}->{FieldValue});
    }

    sub getAttributeName {
        return shift->{_fields}->{AttributeName}->{FieldValue};
    }


    sub setAttributeName    {
        my ($self, $value) = @_;
        $self->{_fields}->{AttributeName}->{FieldValue} = $value;
        return $self;
    }



    sub withAttributeName {
        my $self = shift;
            my $list = $self->{_fields}->{AttributeName}->{FieldValue};
            for (@_) {
                push (@$list, $_);
            }
        return $self;
    }  
      

    sub isSetAttributeName {
        return scalar (@{shift->{_fields}->{AttributeName}->{FieldValue}}) > 0;
    }





1;