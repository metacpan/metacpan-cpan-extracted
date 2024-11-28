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


package Amazon::SQS::Model::SendMessageResult;

use base qw (Amazon::SQS::Model);

    

    #
    # Amazon::SQS::Model::SendMessageResult
    # 
    # Properties:
    #
    # 
    # MessageId: string
    # MD5OfMessageBody: string
    #
    # 
    # 
    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {
            
            MessageId => { FieldValue => undef, FieldType => "string"},
            MD5OfMessageBody => { FieldValue => undef, FieldType => "string"},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data); 
        }
        
        return $self;
    }

    
    sub getMessageId {
        return shift->{_fields}->{MessageId}->{FieldValue};
    }


    sub setMessageId {
        my ($self, $value) = @_;

        $self->{_fields}->{MessageId}->{FieldValue} = $value;
        return $self;
    }


    sub withMessageId {
        my ($self, $value) = @_;
        $self->setMessageId($value);
        return $self;
    }


    sub isSetMessageId {
        return defined (shift->{_fields}->{MessageId}->{FieldValue});
    }


    sub getMD5OfMessageBody {
        return shift->{_fields}->{MD5OfMessageBody}->{FieldValue};
    }


    sub setMD5OfMessageBody {
        my ($self, $value) = @_;

        $self->{_fields}->{MD5OfMessageBody}->{FieldValue} = $value;
        return $self;
    }


    sub withMD5OfMessageBody {
        my ($self, $value) = @_;
        $self->setMD5OfMessageBody($value);
        return $self;
    }


    sub isSetMD5OfMessageBody {
        return defined (shift->{_fields}->{MD5OfMessageBody}->{FieldValue});
    }





1;