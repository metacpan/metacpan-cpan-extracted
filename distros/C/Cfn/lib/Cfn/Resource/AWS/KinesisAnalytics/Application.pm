# AWS::KinesisAnalytics::Application generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisAnalytics::Application->new( %$_ ) };

package Cfn::Resource::AWS::KinesisAnalytics::Application {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::JSONMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::JSONMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::JSONMappingParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::JSONMappingParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordRowPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::CSVMappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::CSVMappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::CSVMappingParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::CSVMappingParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumnDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordRowDelimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::MappingParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::MappingParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::MappingParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::MappingParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CSVMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::CSVMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JSONMappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::JSONMappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordFormat',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordFormat',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::RecordFormat->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::RecordFormat {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MappingParameters => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::MappingParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormatType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordColumn',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordColumn',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordColumn')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordColumn',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordColumn',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::RecordColumn->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::RecordColumn {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Mapping => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputLambdaProcessor',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputLambdaProcessor',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputLambdaProcessor->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputLambdaProcessor {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::KinesisStreamsInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::KinesisStreamsInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::KinesisStreamsInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::KinesisStreamsInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::KinesisFirehoseInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::KinesisFirehoseInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::KinesisFirehoseInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::KinesisFirehoseInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputSchema',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputSchema',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputSchema->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputSchema {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordColumns => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordColumn', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordEncoding => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecordFormat => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::RecordFormat', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputProcessingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputProcessingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputProcessingConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputProcessingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputLambdaProcessor => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputLambdaProcessor', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputParallelism',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputParallelism',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputParallelism->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::InputParallelism {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Count => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::Application::Input',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::Application::Input',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::Input')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::Input',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::Input',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::Input->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::Application::Input {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputParallelism => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputParallelism', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputProcessingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputProcessingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputSchema => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::InputSchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisFirehoseInput => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::KinesisFirehoseInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisStreamsInput => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::Application::KinesisStreamsInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NamePrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::KinesisAnalytics::Application {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ApplicationDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ApplicationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Inputs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::KinesisAnalytics::Application::Input', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::KinesisAnalytics::Application - Cfn resource for AWS::KinesisAnalytics::Application

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::KinesisAnalytics::Application.

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
