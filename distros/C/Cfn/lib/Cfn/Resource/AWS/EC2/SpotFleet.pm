# AWS::EC2::SpotFleet generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::SpotFleet->new( %$_ ) };

package Cfn::Resource::AWS::EC2::SpotFleet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroup',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroup',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroup')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::TargetGroup->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::TargetGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::PrivateIpAddressSpecification',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::PrivateIpAddressSpecification',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::PrivateIpAddressSpecification')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::PrivateIpAddressSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::PrivateIpAddressSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::PrivateIpAddressSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::PrivateIpAddressSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Primary => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrivateIpAddress => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceIpv6Address',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceIpv6Address',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceIpv6Address')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceIpv6Address',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceIpv6Address',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::InstanceIpv6Address->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::InstanceIpv6Address {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Ipv6Address => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::EbsBlockDevice',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::EbsBlockDevice',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::EbsBlockDevice->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::EbsBlockDevice {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeleteOnTermination => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Encrypted => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Iops => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SnapshotId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancer',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancer',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancer')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::ClassicLoadBalancer->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::ClassicLoadBalancer {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroupsConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroupsConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::TargetGroupsConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::TargetGroupsConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TargetGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroup', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotPlacement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotPlacement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotPlacement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotPlacement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityZone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tenancy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetTagSpecification',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetTagSpecification',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetTagSpecification')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetTagSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetTagSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetTagSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetTagSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ResourceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetMonitoring',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetMonitoring',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetMonitoring->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetMonitoring {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotCapacityRebalance',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotCapacityRebalance',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotCapacityRebalance->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotCapacityRebalance {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ReplacementStrategy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateOverrides',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateOverrides',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateOverrides')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateOverrides',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateOverrides',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::LaunchTemplateOverrides->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::LaunchTemplateOverrides {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AvailabilityZone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Priority => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpotPrice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WeightedCapacity => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AssociatePublicIpAddress => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeleteOnTermination => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceIndex => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Groups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Ipv6AddressCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Ipv6Addresses => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceIpv6Address', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkInterfaceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrivateIpAddresses => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::PrivateIpAddressSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecondaryPrivateIpAddressCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::IamInstanceProfileSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::IamInstanceProfileSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::IamInstanceProfileSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::IamInstanceProfileSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::GroupIdentifier',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::GroupIdentifier',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::GroupIdentifier')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::GroupIdentifier',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::GroupIdentifier',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::GroupIdentifier->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::GroupIdentifier {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::FleetLaunchTemplateSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::FleetLaunchTemplateSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::FleetLaunchTemplateSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::FleetLaunchTemplateSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LaunchTemplateId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LaunchTemplateName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancersConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancersConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::ClassicLoadBalancersConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::ClassicLoadBalancersConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClassicLoadBalancers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::BlockDeviceMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::BlockDeviceMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::BlockDeviceMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::BlockDeviceMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::BlockDeviceMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::BlockDeviceMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::BlockDeviceMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeviceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Ebs => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::EbsBlockDevice', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NoDevice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VirtualName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotMaintenanceStrategies',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotMaintenanceStrategies',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotMaintenanceStrategies->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotMaintenanceStrategies {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CapacityRebalance => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotCapacityRebalance', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlockDeviceMappings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::BlockDeviceMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EbsOptimized => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IamInstanceProfile => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::IamInstanceProfileSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ImageId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KernelId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Monitoring => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetMonitoring', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkInterfaces => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::InstanceNetworkInterfaceSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Placement => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotPlacement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RamdiskId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::GroupIdentifier', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpotPrice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TagSpecifications => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetTagSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserData => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WeightedCapacity => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::LoadBalancersConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::LoadBalancersConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::LoadBalancersConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::LoadBalancersConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClassicLoadBalancersConfig => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::ClassicLoadBalancersConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetGroupsConfig => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::TargetGroupsConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateConfig',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateConfig',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateConfig')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::LaunchTemplateConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::LaunchTemplateConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LaunchTemplateSpecification => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::FleetLaunchTemplateSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Overrides => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateOverrides', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetRequestConfigData',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetRequestConfigData',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetRequestConfigData->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::SpotFleet::SpotFleetRequestConfigData {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllocationStrategy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExcessCapacityTerminationPolicy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IamFleetRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceInterruptionBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstancePoolsToUseCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LaunchSpecifications => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetLaunchSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LaunchTemplateConfigs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::SpotFleet::LaunchTemplateConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LoadBalancersConfig => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::LoadBalancersConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OnDemandAllocationStrategy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OnDemandMaxTotalPrice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OnDemandTargetCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ReplaceUnhealthyInstances => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SpotMaintenanceStrategies => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotMaintenanceStrategies', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SpotMaxTotalPrice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SpotPrice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TargetCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TerminateInstancesWithExpiration => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ValidFrom => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ValidUntil => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::EC2::SpotFleet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has SpotFleetRequestConfigData => (isa => 'Cfn::Resource::Properties::AWS::EC2::SpotFleet::SpotFleetRequestConfigData', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EC2::SpotFleet - Cfn resource for AWS::EC2::SpotFleet

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EC2::SpotFleet.

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
