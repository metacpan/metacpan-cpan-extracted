# AWS::FIS::ExperimentTemplate generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate->new( %$_ ) };

package Cfn::Resource::AWS::FIS::ExperimentTemplate {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Id' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterValues',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterValues',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterValues->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterValues {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExperimentTemplateTargetFilterValues => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Path => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterValues', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::TagMap',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::TagMap',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::TagMap->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::TagMap {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ResourceArnList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ResourceArnList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ResourceArnList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ResourceArnList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceArnList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExperimentTemplateTargetFilterList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemTargetMap',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemTargetMap',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemTargetMap->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemTargetMap {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemStartAfterList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemStartAfterList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemStartAfterList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemStartAfterList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExperimentTemplateActionItemStartAfterList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemParameterMap',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemParameterMap',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemParameterMap->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemParameterMap {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'MapOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Filters => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTargetFilterList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceArns => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ResourceArnList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceTags => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::TagMap', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectionMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Source => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ActionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Parameters => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemParameterMap', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StartAfter => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemStartAfterList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Targets => (isa => 'Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateActionItemTargetMap', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::FIS::ExperimentTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Actions => (isa => 'MapOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StopConditions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateStopCondition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Targets => (isa => 'MapOfCfn::Resource::Properties::AWS::FIS::ExperimentTemplate::ExperimentTemplateTarget', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::FIS::ExperimentTemplate - Cfn resource for AWS::FIS::ExperimentTemplate

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::FIS::ExperimentTemplate.

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
