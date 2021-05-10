# AWS::NetworkFirewall::RuleGroup generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup->new( %$_ ) };

package Cfn::Resource::AWS::NetworkFirewall::RuleGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'RuleGroupArn','RuleGroupId' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::TCPFlagField',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::TCPFlagField',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::TCPFlagField')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::TCPFlagField',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::TCPFlagField',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::TCPFlagField->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::TCPFlagField {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Flags => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Masks => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortRange',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortRange',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortRange')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortRange',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortRange',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::PortRange->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::PortRange {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FromPort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ToPort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Dimension',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Dimension',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Dimension')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Dimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Dimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::Dimension->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::Dimension {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Address',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Address',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Address')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Address',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Address',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::Address->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::Address {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AddressDefinition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PublishMetricAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PublishMetricAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::PublishMetricAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::PublishMetricAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Dimensions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Dimension', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::MatchAttributes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::MatchAttributes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::MatchAttributes->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::MatchAttributes {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationPorts => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Destinations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Address', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocols => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourcePorts => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortRange', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Sources => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Address', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TCPFlags => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::TCPFlagField', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchAttributes => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::MatchAttributes', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::ActionDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::ActionDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::ActionDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::ActionDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PublishMetricAction => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PublishMetricAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::StatelessRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::StatelessRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Priority => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleDefinition => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleDefinition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleOption',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleOption',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleOption')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleOption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleOption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleOption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleOption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Keyword => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Settings => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Header',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Header',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::Header->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::Header {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destination => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationPort => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Direction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourcePort => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::CustomAction',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::CustomAction',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::CustomAction')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::CustomAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::CustomAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::CustomAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::CustomAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ActionDefinition => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::ActionDefinition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ActionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRulesAndCustomActions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRulesAndCustomActions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::StatelessRulesAndCustomActions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::StatelessRulesAndCustomActions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomActions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::CustomAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatelessRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRule', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatefulRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatefulRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatefulRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatefulRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatefulRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::StatefulRule->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::StatefulRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Header => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::Header', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleOptions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleOption', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RulesSourceList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RulesSourceList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RulesSourceList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RulesSourceList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GeneratedRulesType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Targets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetTypes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortSet',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortSet',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortSet')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortSet',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortSet',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::PortSet->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::PortSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Definition => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::IPSet',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::IPSet',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::IPSet')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::IPSet',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::IPSet',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::IPSet->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::IPSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Definition => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RulesSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RulesSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RulesSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RulesSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RulesSourceList => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RulesSourceList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RulesString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatefulRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatefulRule', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StatelessRulesAndCustomActions => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::StatelessRulesAndCustomActions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleVariables',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleVariables',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleVariables->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleVariables {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IPSets => (isa => 'MapOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::IPSet', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PortSets => (isa => 'MapOfCfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::PortSet', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleGroup->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::RuleGroup::RuleGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RulesSource => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RulesSource', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleVariables => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleVariables', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Capacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleGroup => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::RuleGroup::RuleGroup', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::NetworkFirewall::RuleGroup - Cfn resource for AWS::NetworkFirewall::RuleGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::NetworkFirewall::RuleGroup.

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
