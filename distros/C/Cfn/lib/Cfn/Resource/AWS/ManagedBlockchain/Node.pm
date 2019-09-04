# AWS::ManagedBlockchain::Node generated from spec 5.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ManagedBlockchain::Node->new( %$_ ) };

package Cfn::Resource::AWS::ManagedBlockchain::Node {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','MemberId','NetworkId','NodeId' ]
  }
  sub supported_regions {
    [ 'us-east-1' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityZone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Node {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MemberId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NodeConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Node::NodeConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
