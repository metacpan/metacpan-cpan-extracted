# AWS::QuickSight::Template generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Template',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::QuickSight::Template->new( %$_ ) };

package Cfn::Resource::AWS::QuickSight::Template {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Template', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CreatedTime','LastUpdatedTime' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Template::DataSetReference',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Template::DataSetReference',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Template::DataSetReference')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Template::DataSetReference',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Template::DataSetReference',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Template::DataSetReference->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Template::DataSetReference {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSetArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSetPlaceholder => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Template::TemplateSourceTemplate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Template::TemplateSourceTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceAnalysis',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceAnalysis',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Template::TemplateSourceAnalysis->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Template::TemplateSourceAnalysis {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSetReferences => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Template::DataSetReference', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceEntity',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceEntity',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Template::TemplateSourceEntity->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Template::TemplateSourceEntity {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SourceAnalysis => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceAnalysis', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceTemplate => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceTemplate', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Template::ResourcePermission',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Template::ResourcePermission',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::Template::ResourcePermission')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::Template::ResourcePermission',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::Template::ResourcePermission',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::Template::ResourcePermission->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::Template::ResourcePermission {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Principal => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::QuickSight::Template {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AwsAccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Permissions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::Template::ResourcePermission', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceEntity => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::Template::TemplateSourceEntity', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TemplateId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VersionDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::QuickSight::Template - Cfn resource for AWS::QuickSight::Template

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::QuickSight::Template.

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
