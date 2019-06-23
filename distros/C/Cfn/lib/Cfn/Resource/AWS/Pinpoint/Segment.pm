# AWS::Pinpoint::Segment generated from spec 3.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Pinpoint::Segment->new( %$_ ) };

package Cfn::Resource::AWS::Pinpoint::Segment {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'SegmentId' ]
  }
  sub supported_regions {
    [ 'ap-south-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Coordinates',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Coordinates',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::CoordinatesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::CoordinatesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Latitude => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Longitude => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimensionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimensionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DimensionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Recency',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Recency',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::RecencyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::RecencyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Duration => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecencyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::GPSPoint',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::GPSPoint',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::GPSPointValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::GPSPointValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Coordinates => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Coordinates', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RangeInKilometers => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Location',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Location',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::LocationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::LocationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Country => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GPSPoint => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::GPSPoint', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Demographic',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Demographic',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::DemographicValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::DemographicValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AppVersion => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Channel => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceType => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Make => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Model => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Platform => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SetDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Behavior',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Behavior',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::BehaviorValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::BehaviorValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Recency => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Recency', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegments',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegments',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegments')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegments',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegments',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegmentsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegmentsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensions',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensions',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensions')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensionsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Behavior => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Behavior', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Demographic => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Demographic', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Location => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Location', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Metrics => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserAttributes => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::Groups',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::Groups',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Pinpoint::Segment::Groups')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Groups',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::Groups',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::GroupsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::GroupsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Dimensions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceSegments => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::SourceSegments', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentGroups',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentGroups',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentGroupsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentGroupsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Groups => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Pinpoint::Segment::Groups', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Include => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::AttributeDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::AttributeDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Pinpoint::Segment::AttributeDimensionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Pinpoint::Segment::AttributeDimensionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttributeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Pinpoint::Segment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Dimensions => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentDimensions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentGroups => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::Segment::SegmentGroups', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
