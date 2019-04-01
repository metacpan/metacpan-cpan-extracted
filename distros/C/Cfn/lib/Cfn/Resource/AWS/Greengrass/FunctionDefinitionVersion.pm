# AWS::Greengrass::FunctionDefinitionVersion generated from spec 2.28.0
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
    [ 'ap-northeast-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
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
       return Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::RunAsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::RunAsValue {
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
       return Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ResourceAccessPolicyValue {
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
       return Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ExecutionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::ExecutionValue {
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
       return Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::EnvironmentValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::EnvironmentValue {
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
       return Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::FunctionConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::FunctionConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EncodingType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Environment => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::Environment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExecArgs => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Executable => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MemorySize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Pinned => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
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
       return Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::FunctionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::FunctionValue {
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
       return Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::DefaultConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinitionVersion::DefaultConfigValue {
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
