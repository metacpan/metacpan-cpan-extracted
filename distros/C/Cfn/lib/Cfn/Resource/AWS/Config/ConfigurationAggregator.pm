# AWS::Config::ConfigurationAggregator generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator->new( %$_ ) };

package Cfn::Resource::AWS::Config::ConfigurationAggregator {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-south-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator::OrganizationAggregationSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator::OrganizationAggregationSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Config::ConfigurationAggregator::OrganizationAggregationSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Config::ConfigurationAggregator::OrganizationAggregationSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllAwsRegions => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsRegions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Config::ConfigurationAggregator::AccountAggregationSource',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Config::ConfigurationAggregator::AccountAggregationSource',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator::AccountAggregationSource')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator::AccountAggregationSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator::AccountAggregationSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Config::ConfigurationAggregator::AccountAggregationSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Config::ConfigurationAggregator::AccountAggregationSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccountIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AllAwsRegions => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsRegions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccountAggregationSources => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Config::ConfigurationAggregator::AccountAggregationSource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConfigurationAggregatorName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OrganizationAggregationSource => (isa => 'Cfn::Resource::Properties::AWS::Config::ConfigurationAggregator::OrganizationAggregationSource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Config::ConfigurationAggregator - Cfn resource for AWS::Config::ConfigurationAggregator

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Config::ConfigurationAggregator.

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
