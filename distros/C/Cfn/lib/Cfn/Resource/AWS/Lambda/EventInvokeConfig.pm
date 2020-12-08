# AWS::Lambda::EventInvokeConfig generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig->new( %$_ ) };

package Cfn::Resource::AWS::Lambda::EventInvokeConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::OnSuccess',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::OnSuccess',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Lambda::EventInvokeConfig::OnSuccess->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Lambda::EventInvokeConfig::OnSuccess {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::OnFailure',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::OnFailure',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Lambda::EventInvokeConfig::OnFailure->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Lambda::EventInvokeConfig::OnFailure {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::DestinationConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::DestinationConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Lambda::EventInvokeConfig::DestinationConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Lambda::EventInvokeConfig::DestinationConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OnFailure => (isa => 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::OnFailure', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnSuccess => (isa => 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::OnSuccess', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DestinationConfig => (isa => 'Cfn::Resource::Properties::AWS::Lambda::EventInvokeConfig::DestinationConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FunctionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MaximumEventAgeInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaximumRetryAttempts => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Qualifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Lambda::EventInvokeConfig - Cfn resource for AWS::Lambda::EventInvokeConfig

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Lambda::EventInvokeConfig.

See L<Cfn> for more information on how to use it.

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
