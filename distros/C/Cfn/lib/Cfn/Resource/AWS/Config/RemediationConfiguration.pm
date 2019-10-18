# AWS::Config::RemediationConfiguration generated from spec 6.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Config::RemediationConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::Config::RemediationConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::StaticValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::StaticValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::StaticValueValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::StaticValueValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::SsmControls',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::SsmControls',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::SsmControlsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::SsmControlsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConcurrentExecutionRatePercentage => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ErrorPercentage => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ResourceValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ResourceValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ResourceValueValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ResourceValueValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::RemediationParameterValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::RemediationParameterValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::RemediationParameterValueValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::RemediationParameterValueValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceValue => (isa => 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ResourceValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StaticValue => (isa => 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::StaticValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ExecutionControls',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ExecutionControls',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ExecutionControlsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ExecutionControlsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SsmControls => (isa => 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::SsmControls', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Config::RemediationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Automatic => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConfigRuleName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExecutionControls => (isa => 'Cfn::Resource::Properties::AWS::Config::RemediationConfiguration::ExecutionControls', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaximumAutomaticAttempts => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Parameters => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetryAttemptSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
