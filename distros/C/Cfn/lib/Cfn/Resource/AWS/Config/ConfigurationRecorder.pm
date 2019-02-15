# AWS::Config::ConfigurationRecorder generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder->new( %$_ ) };

package Cfn::Resource::AWS::Config::ConfigurationRecorder {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder::RecordingGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder::RecordingGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder::RecordingGroupValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder::RecordingGroupValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllSupported => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeGlobalResourceTypes => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceTypes => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RecordingGroup => (isa => 'Cfn::Resource::Properties::AWS::Config::ConfigurationRecorder::RecordingGroup', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
