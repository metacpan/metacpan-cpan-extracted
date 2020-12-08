# AWS::SageMaker::Workteam generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Workteam',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::Workteam->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::Workteam {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Workteam', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'WorkteamName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::CognitoMemberDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::CognitoMemberDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Workteam::CognitoMemberDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Workteam::CognitoMemberDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CognitoClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CognitoUserGroup => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CognitoUserPool => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::NotificationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::NotificationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Workteam::NotificationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Workteam::NotificationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NotificationTopicArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Workteam::MemberDefinition',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Workteam::MemberDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::Workteam::MemberDefinition')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::MemberDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::MemberDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Workteam::MemberDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Workteam::MemberDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CognitoMemberDefinition => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::CognitoMemberDefinition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::Workteam {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MemberDefinitions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Workteam::MemberDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Workteam::NotificationConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WorkteamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::Workteam - Cfn resource for AWS::SageMaker::Workteam

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::Workteam.

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
