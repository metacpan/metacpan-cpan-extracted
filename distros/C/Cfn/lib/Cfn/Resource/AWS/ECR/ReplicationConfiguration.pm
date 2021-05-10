# AWS::ECR::ReplicationConfiguration generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::ECR::ReplicationConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'RegistryId' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationDestination',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationDestination',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationDestination')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ECR::ReplicationConfiguration::ReplicationDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ECR::ReplicationConfiguration::ReplicationDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Region => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegistryId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ECR::ReplicationConfiguration::ReplicationRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ECR::ReplicationConfiguration::ReplicationRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destinations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationDestination', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ECR::ReplicationConfiguration::ReplicationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ECR::ReplicationConfiguration::ReplicationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Rules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationRule', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ReplicationConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ECR::ReplicationConfiguration::ReplicationConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ECR::ReplicationConfiguration - Cfn resource for AWS::ECR::ReplicationConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ECR::ReplicationConfiguration.

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
