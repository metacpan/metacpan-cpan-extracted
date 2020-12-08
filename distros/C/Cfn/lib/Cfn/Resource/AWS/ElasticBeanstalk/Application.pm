# AWS::ElasticBeanstalk::Application generated from spec 18.4.0
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
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::MaxCountRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::MaxCountRule {
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
       return Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::MaxAgeRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::MaxAgeRule {
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
       return Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::ApplicationVersionLifecycleConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::ApplicationVersionLifecycleConfig {
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
       return Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::ApplicationResourceLifecycleConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticBeanstalk::Application::ApplicationResourceLifecycleConfig {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ElasticBeanstalk::Application - Cfn resource for AWS::ElasticBeanstalk::Application

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ElasticBeanstalk::Application.

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
