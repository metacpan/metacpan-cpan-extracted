# AWS::IoTAnalytics::Pipeline generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline->new( %$_ ) };

package Cfn::Resource::AWS::IoTAnalytics::Pipeline {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::SelectAttributes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::SelectAttributes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::SelectAttributes->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::SelectAttributes {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::RemoveAttributes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::RemoveAttributes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::RemoveAttributes->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::RemoveAttributes {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Math',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Math',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Math->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Math {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Math => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Lambda',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Lambda',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Lambda->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Lambda {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BatchSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Filter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Filter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Filter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Filter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Filter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::DeviceShadowEnrich',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::DeviceShadowEnrich',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::DeviceShadowEnrich->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::DeviceShadowEnrich {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThingName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::DeviceRegistryEnrich',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::DeviceRegistryEnrich',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::DeviceRegistryEnrich->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::DeviceRegistryEnrich {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThingName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Datastore',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Datastore',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Datastore->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Datastore {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatastoreName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Channel',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Channel',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Channel->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Channel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChannelName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::AddAttributes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::AddAttributes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::AddAttributes->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::AddAttributes {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Next => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Activity',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Activity',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Activity')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Activity',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Activity',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Activity->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTAnalytics::Pipeline::Activity {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AddAttributes => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::AddAttributes', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Channel => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Channel', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Datastore => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Datastore', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceRegistryEnrich => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::DeviceRegistryEnrich', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceShadowEnrich => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::DeviceShadowEnrich', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Filter => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Filter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Lambda => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Lambda', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Math => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Math', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RemoveAttributes => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::RemoveAttributes', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectAttributes => (isa => 'Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::SelectAttributes', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTAnalytics::Pipeline {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has PipelineActivities => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTAnalytics::Pipeline::Activity', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PipelineName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTAnalytics::Pipeline - Cfn resource for AWS::IoTAnalytics::Pipeline

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTAnalytics::Pipeline.

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
