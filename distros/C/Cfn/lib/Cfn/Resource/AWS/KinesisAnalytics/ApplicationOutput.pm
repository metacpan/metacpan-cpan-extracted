# AWS::KinesisAnalytics::ApplicationOutput generated from spec 3.2.0
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
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::LambdaOutputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::LambdaOutputValue {
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
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisStreamsOutputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisStreamsOutputValue {
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
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisFirehoseOutputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::KinesisFirehoseOutputValue {
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
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::DestinationSchemaValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::DestinationSchemaValue {
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
       return Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::OutputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::KinesisAnalytics::ApplicationOutput::OutputValue {
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
