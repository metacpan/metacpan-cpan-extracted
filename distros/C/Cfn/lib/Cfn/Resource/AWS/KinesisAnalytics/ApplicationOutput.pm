# AWS::KinesisAnalytics::ApplicationOutput generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput->new( %$_ ) };

package Cfn::Resource::AWS::KinesisAnalytics::ApplicationOutput {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::LambdaOutput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::LambdaOutput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::LambdaOutput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::LambdaOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisStreamsOutput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisStreamsOutput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::KinesisStreamsOutput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::KinesisStreamsOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisFirehoseOutput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisFirehoseOutput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::KinesisFirehoseOutput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::KinesisFirehoseOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::DestinationSchema',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::DestinationSchema',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::DestinationSchema->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::DestinationSchema {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RecordFormatType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::Output',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::Output',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::Output->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::KinesisAnalytics::ApplicationOutput::Output {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationSchema => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::DestinationSchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisFirehoseOutput => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisFirehoseOutput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisStreamsOutput => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisStreamsOutput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LambdaOutput => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::LambdaOutput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Output => (isa => 'Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::Output', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::KinesisAnalytics::ApplicationOutput - Cfn resource for AWS::KinesisAnalytics::ApplicationOutput

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::KinesisAnalytics::ApplicationOutput.

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
