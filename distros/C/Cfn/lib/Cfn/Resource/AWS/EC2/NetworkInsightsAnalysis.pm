# AWS::EC2::NetworkInsightsAnalysis generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis->new( %$_ ) };

package Cfn::Resource::AWS::EC2::NetworkInsightsAnalysis {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AlternatePathHints','Explanations','ForwardPathComponents','NetworkInsightsAnalysisArn','NetworkInsightsAnalysisId','NetworkPathFound','ReturnPathComponents','StartDate','Status','StatusMessage' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::PortRange->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::PortRange {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has From => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has To => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisSecurityGroupRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisSecurityGroupRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisSecurityGroupRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisSecurityGroupRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Cidr => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Direction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PortRange => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrefixListId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisRouteTableRoute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisRouteTableRoute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisRouteTableRoute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisRouteTableRoute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has destinationCidr => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has destinationPrefixListId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has egressOnlyInternetGatewayId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has gatewayId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has instanceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NatGatewayId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkInterfaceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Origin => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TransitGatewayId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcPeeringConnectionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisPacketHeader',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisPacketHeader',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisPacketHeader->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisPacketHeader {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationAddresses => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationPortRanges => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceAddresses => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourcePortRanges => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerTarget',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerTarget',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerTarget->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerTarget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Address => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AvailabilityZone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Instance => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerListener',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerListener',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerListener->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerListener {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstancePort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerPort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisAclRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisAclRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisAclRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AnalysisAclRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Cidr => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Egress => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PortRange => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleAction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PathComponent',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PathComponent',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::PathComponent->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::PathComponent {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AclRule => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisAclRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Component => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationVpc => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InboundHeader => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisPacketHeader', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutboundHeader => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisPacketHeader', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RouteTableRoute => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisRouteTableRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroupRule => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisSecurityGroupRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SequenceNumber => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceVpc => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Subnet => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Vpc => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::Explanation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::Explanation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::Explanation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::Explanation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Acl => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AclRule => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisAclRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Address => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Addresses => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AttachedTo => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AvailabilityZones => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Cidrs => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClassicLoadBalancerListener => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerListener', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Component => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CustomerGateway => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destination => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationVpc => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Direction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ElasticLoadBalancerListener => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExplanationCode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IngressRouteTable => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InternetGateway => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerListenerPort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerTarget => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisLoadBalancerTarget', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerTargetGroup => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerTargetGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerTargetPort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MissingComponent => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NatGateway => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NetworkInterface => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PacketField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PortRanges => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::PortRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrefixList => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocols => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RouteTable => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RouteTableRoute => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisRouteTableRoute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroup => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroupRule => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisSecurityGroupRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceVpc => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has State => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Subnet => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetRouteTable => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Vpc => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has vpcEndpoint => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcPeeringConnection => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpnConnection => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpnGateway => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AnalysisComponent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AlternatePathHint',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis::AlternatePathHint',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AlternatePathHint->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::EC2::NetworkInsightsAnalysis::AlternatePathHint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComponentArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ComponentId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::EC2::NetworkInsightsAnalysis {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has FilterInArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NetworkInsightsPathId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EC2::NetworkInsightsAnalysis - Cfn resource for AWS::EC2::NetworkInsightsAnalysis

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EC2::NetworkInsightsAnalysis.

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
