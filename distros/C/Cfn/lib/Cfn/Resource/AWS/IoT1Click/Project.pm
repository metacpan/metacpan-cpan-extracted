# AWS::IoT1Click::Project generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Project',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT1Click::Project->new( %$_ ) };

package Cfn::Resource::AWS::IoT1Click::Project {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT1Click::Project', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','ProjectName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT1Click::Project::PlacementTemplate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT1Click::Project::PlacementTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultAttributes => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceTemplates => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT1Click::Project::DeviceTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Project::DeviceTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT1Click::Project::DeviceTemplate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT1Click::Project::DeviceTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CallbackOverrides => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoT1Click::Project {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PlacementTemplate => (isa => 'Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplate', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProjectName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoT1Click::Project - Cfn resource for AWS::IoT1Click::Project

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoT1Click::Project.

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
