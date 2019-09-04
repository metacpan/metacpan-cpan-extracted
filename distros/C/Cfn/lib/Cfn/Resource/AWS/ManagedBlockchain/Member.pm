# AWS::ManagedBlockchain::Member generated from spec 5.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ManagedBlockchain::Member->new( %$_ ) };

package Cfn::Resource::AWS::ManagedBlockchain::Member {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'MemberId','NetworkId' ]
  }
  sub supported_regions {
    [ 'us-east-1' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFabricConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFabricConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFabricConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFabricConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Edition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFabricConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFabricConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFabricConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFabricConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdminPassword => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdminUsername => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::ApprovalThresholdPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::ApprovalThresholdPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::ApprovalThresholdPolicyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::ApprovalThresholdPolicyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ProposalDurationInHours => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThresholdComparator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThresholdPercentage => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::VotingPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::VotingPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::VotingPolicyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::VotingPolicyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApprovalThresholdPolicy => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::ApprovalThresholdPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFrameworkConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFrameworkConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFrameworkConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFrameworkConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NetworkFabricConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFabricConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFrameworkConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFrameworkConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFrameworkConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFrameworkConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MemberFabricConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFabricConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Framework => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FrameworkVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkFrameworkConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkFrameworkConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VotingPolicy => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::VotingPolicy', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MemberFrameworkConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberFrameworkConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ManagedBlockchain::Member {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has InvitationId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MemberConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::MemberConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ManagedBlockchain::Member::NetworkConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
