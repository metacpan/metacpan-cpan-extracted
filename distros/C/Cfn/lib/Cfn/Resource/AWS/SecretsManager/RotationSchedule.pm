# AWS::SecretsManager::RotationSchedule generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule->new( %$_ ) };

package Cfn::Resource::AWS::SecretsManager::RotationSchedule {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRules',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRules',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SecretsManager::RotationSchedule::RotationRules->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SecretsManager::RotationSchedule::RotationRules {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutomaticallyAfterDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::HostedRotationLambda',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::HostedRotationLambda',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SecretsManager::RotationSchedule::HostedRotationLambda->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SecretsManager::RotationSchedule::HostedRotationLambda {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KmsKeyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MasterSecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MasterSecretKmsKeyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RotationLambdaName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RotationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcSecurityGroupIds => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcSubnetIds => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has HostedRotationLambda => (isa => 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::HostedRotationLambda', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RotationLambdaARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RotationRules => (isa => 'Cfn::Resource::Properties::AWS::SecretsManager::RotationSchedule::RotationRules', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SecretsManager::RotationSchedule - Cfn resource for AWS::SecretsManager::RotationSchedule

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SecretsManager::RotationSchedule.

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
