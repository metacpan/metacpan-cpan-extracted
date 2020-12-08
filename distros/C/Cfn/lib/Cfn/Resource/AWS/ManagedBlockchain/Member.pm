# AWS::ManagedBlockchain::Member generated from spec 18.4.0
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
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::NetworkFabricConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::NetworkFabricConfiguration {
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::MemberFabricConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::MemberFabricConfiguration {
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::ApprovalThresholdPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::ApprovalThresholdPolicy {
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::VotingPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::VotingPolicy {
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::NetworkFrameworkConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::NetworkFrameworkConfiguration {
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::MemberFrameworkConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::MemberFrameworkConfiguration {
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::NetworkConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::NetworkConfiguration {
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
       return Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::MemberConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ManagedBlockchain::Member::MemberConfiguration {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ManagedBlockchain::Member - Cfn resource for AWS::ManagedBlockchain::Member

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ManagedBlockchain::Member.

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
