# AWS::CodeCommit::Repository generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CodeCommit::Repository',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CodeCommit::Repository->new( %$_ ) };

package Cfn::Resource::AWS::CodeCommit::Repository {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CodeCommit::Repository', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CloneUrlHttp','CloneUrlSsh','Name' ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::S3',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::S3',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CodeCommit::Repository::S3->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CodeCommit::Repository::S3 {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ObjectVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::CodeCommit::Repository::RepositoryTrigger',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::CodeCommit::Repository::RepositoryTrigger',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::CodeCommit::Repository::RepositoryTrigger')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::RepositoryTrigger',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::RepositoryTrigger',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CodeCommit::Repository::RepositoryTrigger->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CodeCommit::Repository::RepositoryTrigger {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Branches => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomData => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Events => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::Code',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::Code',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CodeCommit::Repository::Code->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CodeCommit::Repository::Code {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BranchName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3 => (isa => 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::S3', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::CodeCommit::Repository {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Code => (isa => 'Cfn::Resource::Properties::AWS::CodeCommit::Repository::Code', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepositoryDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepositoryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Triggers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::CodeCommit::Repository::RepositoryTrigger', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CodeCommit::Repository - Cfn resource for AWS::CodeCommit::Repository

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CodeCommit::Repository.

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
