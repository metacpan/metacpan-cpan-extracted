# AWS::ApplicationInsights::Application generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApplicationInsights::Application->new( %$_ ) };

package Cfn::Resource::AWS::ApplicationInsights::Application {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ApplicationARN' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::WindowsEvent',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::WindowsEvent',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::WindowsEvent')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::WindowsEvent',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::WindowsEvent',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::WindowsEvent->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::WindowsEvent {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EventLevels => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PatternSet => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::Log',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::Log',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::Log')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::Log',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::Log',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::Log->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::Log {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Encoding => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PatternSet => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::AlarmMetric',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::AlarmMetric',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::AlarmMetric')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::AlarmMetric',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::AlarmMetric',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::AlarmMetric->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::AlarmMetric {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AlarmMetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentConfigurationDetails',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentConfigurationDetails',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::SubComponentConfigurationDetails->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::SubComponentConfigurationDetails {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AlarmMetrics => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::AlarmMetric', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Logs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::Log', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WindowsEvents => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::WindowsEvent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::JMXPrometheusExporter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::JMXPrometheusExporter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::JMXPrometheusExporter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::JMXPrometheusExporter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HostPort => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JMXURL => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrometheusPort => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::Alarm',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::Alarm',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::Alarm')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::Alarm',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::Alarm',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::Alarm->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::Alarm {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AlarmName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Severity => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SubComponentConfigurationDetails => (isa => 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentConfigurationDetails', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubComponentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ConfigurationDetails',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ConfigurationDetails',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::ConfigurationDetails->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::ConfigurationDetails {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AlarmMetrics => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::AlarmMetric', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Alarms => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::Alarm', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JMXPrometheusExporter => (isa => 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::JMXPrometheusExporter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Logs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::Log', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WindowsEvents => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::WindowsEvent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPattern',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPattern',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPattern')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPattern',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPattern',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::LogPattern->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::LogPattern {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Pattern => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PatternName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rank => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::ComponentConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::ComponentConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfigurationDetails => (isa => 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ConfigurationDetails', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubComponentTypeConfigurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::SubComponentTypeConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPatternSet',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPatternSet',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPatternSet')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPatternSet',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPatternSet',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::LogPatternSet->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::LogPatternSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogPatterns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPattern', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PatternSetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::CustomComponent',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::CustomComponent',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::CustomComponent')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::CustomComponent',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::CustomComponent',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::CustomComponent->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::CustomComponent {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComponentName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentMonitoringSetting',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentMonitoringSetting',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentMonitoringSetting')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentMonitoringSetting',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentMonitoringSetting',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::ComponentMonitoringSetting->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationInsights::Application::ComponentMonitoringSetting {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComponentARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ComponentConfigurationMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ComponentName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomComponentConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultOverwriteComponentConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ApplicationInsights::Application {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AutoConfigurationEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CWEMonitorEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ComponentMonitoringSettings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::ComponentMonitoringSetting', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomComponents => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::CustomComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogPatternSets => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationInsights::Application::LogPatternSet', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OpsCenterEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OpsItemSNSTopicArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ApplicationInsights::Application - Cfn resource for AWS::ApplicationInsights::Application

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ApplicationInsights::Application.

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
