# AWS::ElasticBeanstalk::Application generated from spec 2.25.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application->new( %$_ ) };

package Cfn::Resource::AWS::ElasticBeanstalk::Application {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxCountRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxCountRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxCountRuleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxCountRuleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeleteSourceFromS3 => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxAgeRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxAgeRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxAgeRuleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxAgeRuleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeleteSourceFromS3 => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxAgeInDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationVersionLifecycleConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationVersionLifecycleConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationVersionLifecycleConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationVersionLifecycleConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxAgeRule => (isa => 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxAgeRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxCountRule => (isa => 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::MaxCountRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationResourceLifecycleConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationResourceLifecycleConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationResourceLifecycleConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationResourceLifecycleConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ServiceRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VersionLifecycleConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationVersionLifecycleConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceLifecycleConfig => (isa => 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application::ApplicationResourceLifecycleConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
