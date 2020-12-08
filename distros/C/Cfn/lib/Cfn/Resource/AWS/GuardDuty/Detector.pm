# AWS::GuardDuty::Detector generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::GuardDuty::Detector',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::GuardDuty::Detector->new( %$_ ) };

package Cfn::Resource::AWS::GuardDuty::Detector {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::GuardDuty::Detector', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::GuardDuty::Detector::CFNS3LogsConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GuardDuty::Detector::CFNS3LogsConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GuardDuty::Detector::CFNS3LogsConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GuardDuty::Detector::CFNS3LogsConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enable => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GuardDuty::Detector::CFNDataSourceConfigurations',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GuardDuty::Detector::CFNDataSourceConfigurations',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GuardDuty::Detector::CFNDataSourceConfigurations->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GuardDuty::Detector::CFNDataSourceConfigurations {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Logs => (isa => 'Cfn::Resource::Properties::AWS::GuardDuty::Detector::CFNS3LogsConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::GuardDuty::Detector {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DataSources => (isa => 'Cfn::Resource::Properties::AWS::GuardDuty::Detector::CFNDataSourceConfigurations', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enable => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FindingPublishingFrequency => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::GuardDuty::Detector - Cfn resource for AWS::GuardDuty::Detector

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::GuardDuty::Detector.

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
