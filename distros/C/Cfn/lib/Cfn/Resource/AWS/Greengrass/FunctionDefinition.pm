# AWS::Greengrass::FunctionDefinition generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::FunctionDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','LatestVersionArn','Name' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::RunAs',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::RunAs',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::RunAs->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::RunAs {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Gid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Uid => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Permission => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Execution',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Execution',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::Execution->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::Execution {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IsolationMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RunAs => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::RunAs', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Environment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Environment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::Environment->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::Environment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessSysfs => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Execution => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Execution', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ResourceAccessPolicies => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::ResourceAccessPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Variables => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::FunctionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::FunctionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::FunctionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::FunctionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EncodingType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Environment => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Environment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExecArgs => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Executable => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MemorySize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Pinned => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Function',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Function',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Function')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Function',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Function',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::Function->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::Function {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FunctionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FunctionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::FunctionConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::DefaultConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::DefaultConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::DefaultConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::DefaultConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Execution => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Execution', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::FunctionDefinitionVersion',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::FunctionDefinitionVersion',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::FunctionDefinitionVersion->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Greengrass::FunctionDefinition::FunctionDefinitionVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultConfig => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::DefaultConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Functions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::Function', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has InitialVersion => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::FunctionDefinition::FunctionDefinitionVersion', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Greengrass::FunctionDefinition - Cfn resource for AWS::Greengrass::FunctionDefinition

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Greengrass::FunctionDefinition.

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
