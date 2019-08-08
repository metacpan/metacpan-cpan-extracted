# AWS::SSM::MaintenanceWindowTask generated from spec 5.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask->new( %$_ ) };

package Cfn::Resource::AWS::SSM::MaintenanceWindowTask {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::NotificationConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::NotificationConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::NotificationConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::NotificationConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NotificationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationEvents => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowStepFunctionsParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowStepFunctionsParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowStepFunctionsParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowStepFunctionsParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Input => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowRunCommandParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowRunCommandParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowRunCommandParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowRunCommandParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Comment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentHash => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentHashType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationConfig => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::NotificationConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputS3BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputS3KeyPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Parameters => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeoutSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowLambdaParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowLambdaParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowLambdaParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowLambdaParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientContext => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Payload => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Qualifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowAutomationParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowAutomationParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowAutomationParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowAutomationParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DocumentVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Parameters => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::TaskInvocationParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::TaskInvocationParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::TaskInvocationParametersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::TaskInvocationParametersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaintenanceWindowAutomationParameters => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowAutomationParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaintenanceWindowLambdaParameters => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowLambdaParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaintenanceWindowRunCommandParameters => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowRunCommandParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaintenanceWindowStepFunctionsParameters => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::MaintenanceWindowStepFunctionsParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::Target',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::Target',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::Target')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::Target',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::Target',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::TargetValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::TargetValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::LoggingInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::LoggingInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::LoggingInfoValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::LoggingInfoValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Region => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoggingInfo => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::LoggingInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxConcurrency => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxErrors => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Targets => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::Target', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TaskArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TaskInvocationParameters => (isa => 'Cfn::Resource::Properties::AWS::SSM::MaintenanceWindowTask::TaskInvocationParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TaskParameters => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TaskType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WindowId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
