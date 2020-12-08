# AWS::Greengrass::FunctionDefinitionVersion generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::FunctionDefinitionVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::RunAs',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::RunAs',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::RunAs->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::RunAs {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Gid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Uid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Permission => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Execution',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Execution',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::Execution->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::Execution {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IsolationMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RunAs => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::RunAs', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Environment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Environment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::Environment->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::Environment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessSysfs => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Execution => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Execution', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourceAccessPolicies => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Variables => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::FunctionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::FunctionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::FunctionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::FunctionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EncodingType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Environment => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Environment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExecArgs => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Executable => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MemorySize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Pinned => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Function',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Function',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Function')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Function',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Function',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::Function->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::Function {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FunctionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FunctionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::FunctionConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::DefaultConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::DefaultConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::DefaultConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinitionVersion::DefaultConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Execution => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Execution', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DefaultConfig => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::DefaultConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FunctionDefinitionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Functions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Function', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Greengrass::FunctionDefinitionVersion - Cfn resource for AWS::Greengrass::FunctionDefinitionVersion

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Greengrass::FunctionDefinitionVersion.

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
