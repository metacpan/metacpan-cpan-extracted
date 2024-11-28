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


package Amazon::SQS::Model::GetQueueAttributesResult;

use base qw (Amazon::SQS::Model);

    

    #
    # Amazon::SQS::Model::GetQueueAttributesResult
    # 
    # Properties:
    #
    # 
    # Attribute: Amazon::SQS::Model::Attribute
    #
    # 
    # 
    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {
            
            Attribute => {FieldValue => [], FieldType => ["Amazon::SQS::Model::Attribute"]},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data); 
        }
        
        return $self;
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





1;