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


package Amazon::SQS::Model::ReceiveMessageResult;

use base qw (Amazon::SQS::Model);

    

    #
    # Amazon::SQS::Model::ReceiveMessageResult
    # 
    # Properties:
    #
    # 
    # Message: Amazon::SQS::Model::Message
    #
    # 
    # 
    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {
            
            Message => {FieldValue => [], FieldType => ["Amazon::SQS::Model::Message"]},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data); 
        }
        
        return $self;
    }

        sub getMessage {
        return shift->{_fields}->{Message}->{FieldValue};
    }

    sub setMessage {
        my $self = shift;
        foreach my $message (@_) {
            if (not $self->_isArrayRef($message)) {
                $message =  [$message];    
            }
            $self->{_fields}->{Message}->{FieldValue} = $message;
        }
    }


    sub withMessage {
        my ($self, $messageArgs) = @_;
        foreach my $message (@$messageArgs) {
            $self->{_fields}->{Message}->{FieldValue} = $message;
        }
        return $self;
    }   


    sub isSetMessage {
        return  scalar (@{shift->{_fields}->{Message}->{FieldValue}}) > 0;
    }





1;