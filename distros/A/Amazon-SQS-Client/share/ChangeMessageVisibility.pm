#!@perlrun@
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

#
# Change Message Visibility  Sample
#

use strict;
use Carp qw( carp croak );
  
 #***********************************************************************
 # Access Key ID and Secret Acess Key ID, obtained from:
 # http://aws.amazon.com
 #**********************************************************************/
 
 require Amazon::SQS::Config;

 my $config = new Amazon::SQS::Config( '@aws_sqsdir@/aws-sqs.ini' );

 my $AWS_ACCESS_KEY_ID     = $config->aws_access_key_id;
 my $AWS_SECRET_ACCESS_KEY = $config->aws_secret_access_key;

 #***********************************************************************
 # Instantiate Http Client Implementation of SQS 
 #**********************************************************************/
 use Amazon::SQS::Client; 
 my $service = Amazon::SQS::Client->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY);
 
 #************************************************************************
 # Uncomment to try out Mock Service that simulates Amazon::SQS
 # responses without calling Amazon::SQS service.
 #
 # Responses are loaded from local XML files. You can tweak XML files to
 # experiment with various outputs during development
 #
 # XML files available under Amazon/SQS/Mock tree
 #
 #**********************************************************************/
 # use Amazon::SQS::Mock;  
 # my $service = Amazon::SQS::Mock->new;

 #************************************************************************
 # Setup request parameters and uncomment invoke to try out 
 # sample for Change Message Visibility Action
 #**********************************************************************/
 use Amazon::SQS::Model::ChangeMessageVisibilityRequest;
 # @TODO: set request. Action can be passed as Amazon::SQS::Model::ChangeMessageVisibilityRequest
 # object or hash of parameters
 # invokeChangeMessageVisibility($service, $request);

                                    
    # 
    # Change Message Visibility Action Sample
    #
  sub invokeChangeMessageVisibility {
      my ($service, $request) = @_;  
      eval {
              my $response = $service->changeMessageVisibility($request);
              
                print ("Service Response\n");
                print ("=============================================================================\n");

                print("        ChangeMessageVisibilityResponse\n");
                if ($response->isSetResponseMetadata()) { 
                    print("            ResponseMetadata\n");
                    my $responseMetadata = $response->getResponseMetadata();
                    if ($responseMetadata->isSetRequestId()) 
                    {
                        print("                RequestId\n");
                        print("                    " . $responseMetadata->getRequestId() . "\n");
                    }
                } 

           
     };
    my $ex = $@;
    if ($ex) {
        require Amazon::SQS::Exception;
        if (ref $ex eq "Amazon::SQS::Exception") {
            print("Caught Exception: " . $ex->getMessage() . "\n");
            print("Response Status Code: " . $ex->getStatusCode() . "\n");
            print("Error Code: " . $ex->getErrorCode() . "\n");
            print("Error Type: " . $ex->getErrorType() . "\n");
            print("Request ID: " . $ex->getRequestId() . "\n");
            print("XML: " . $ex->getXML() . "\n");
        } else {
            croak $@;
        }
    }
 }

                                