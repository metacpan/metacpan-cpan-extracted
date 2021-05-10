package Cfn::TypeLibrary {
  use Moose::Util::TypeConstraints;

  sub try_function {
    my $arg = shift;
    my @keys = keys %$arg;
    my $first_key = $keys[0];
    if (@keys == 1 and (substr($first_key,0,4) eq 'Fn::' or $first_key eq 'Ref' or $first_key eq 'Condition')){
      if ($first_key eq 'Fn::GetAtt') { 
        return Cfn::Value::Function::GetAtt->new(Function => $first_key, Value => $arg->{ $first_key });
      } elsif ($keys[0] eq 'Ref'){
        my $psdparam = Moose::Util::TypeConstraints::find_type_constraint('Cfn::PseudoParameterValue');
        my $value = $arg->{ $first_key };
        my $class = $psdparam->check($value) ? 
                      'Cfn::Value::Function::PseudoParameter' : 
                      'Cfn::Value::Function::Ref';
        
        return $class->new( Function => $first_key, Value => $value);
      } elsif ($keys[0] eq 'Condition'){
        return Cfn::Value::Function::Condition->new( Function => $first_key, Value => $arg->{ $first_key });
      } else {
        return Cfn::Value::Function->new(Function => $first_key, Value => $arg->{ $first_key });
      }
    } else {
      return undef;
    }
  }
  
  coerce 'Cfn::Resource::UpdatePolicy',
    from 'HashRef',
    via { Cfn::Resource::UpdatePolicy->new( %$_ ) };

  coerce 'Cfn::Resource::UpdatePolicy::AutoScalingReplacingUpdate',
    from 'HashRef',
    via { Cfn::Resource::UpdatePolicy::AutoScalingReplacingUpdate->new( %$_ ) };

  coerce 'Cfn::Resource::UpdatePolicy::AutoScalingRollingUpdate',
    from 'HashRef',
    via { Cfn::Resource::UpdatePolicy::AutoScalingRollingUpdate->new( %$_ ) };

  coerce 'Cfn::Resource::UpdatePolicy::AutoScalingScheduledAction',
    from 'HashRef',
    via { Cfn::Resource::UpdatePolicy::AutoScalingScheduledAction->new( %$_ ) };

  subtype 'Cfn::Resource::UpdatePolicy::AutoScalingRollingUpdate::SuspendProcesses',
    as 'Cfn::Value::Array',
    where {
      my $array = $_->Value;

      my $valid = { Launch => 1, Terminate => 1, HealthCheck => 1, ReplaceUnhealthy => 1,
                    AZRebalance => 1, AlarmNotification =>1, ScheduledActions => 1,
                    AddToLoadBalancer => 1 };

      my @val = grep { $valid->{ $_->Value } } @$array;
      # The array is valid if all of it's values are found in $valid
      return @val == @$array;
    },
    message { 'This type only supports the following values in the array: "Launch, Terminate, HealthCheck, ReplaceUnhealthy, AZRebalance, AlarmNotification, ScheduledActions, AddToLoadBalancer"' };

  coerce 'Cfn::Resource::UpdatePolicy::AutoScalingRollingUpdate::SuspendProcesses',
    from 'HashRef',  via (\&coerce_hash),
    from 'ArrayRef', via (\&coerce_array);

  subtype 'Cfn::Resource::DeletionPolicy',
    as 'Str',
    where { $_ eq 'Delete' or $_ eq 'Retain' or $_ eq 'Snapshot' },
    message { "$_ is an invalid DeletionPolicy" };

  subtype 'Cfn::Resource::UpdateReplacePolicy',
    as 'Str',
    where { $_ eq 'Delete' or $_ eq 'Retain' or $_ eq 'Snapshot' },
    message { "$_ is an invalid UpdateReplacePolicy" };

  subtype 'Cfn::Value::ArrayOfPrimitives',
    as 'Cfn::Value::Array',
    where { @{ $_[0]->Value } == grep { $_->isa('Cfn::Value::Primitive') } @{ $_[0]->Value } },
    message { 'This type only supports Primitives' };

  sub coerce_array {
    Cfn::Value::Array->new(Value => [
      map { Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($_) } @$_
    ])
  }

  sub coerce_hash  {
    my $arg = $_;
    my $function = try_function($arg);
    return $function if (defined $function);
    my @keys = keys %$arg;
    return Cfn::Value::Hash->new(Value => {
      map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($arg->{$_}) } @keys
    });
  }

  sub coerce_hashref_to_function {
    my $val = $_;
    my $function = try_function($val);
    return $function if (defined $function);
    die "Is not a function";
  }

  coerce 'Cfn::Value',
    from 'Value',  via { Cfn::Value::Primitive->new( Value => $_ ) },
    from 'HashRef',  via (\&coerce_hash),
    from 'ArrayRef', via (\&coerce_array);

  subtype 'Cfn::Value::Boolean',   as 'Cfn::Value';
  subtype 'Cfn::Value::Integer',   as 'Cfn::Value';
  subtype 'Cfn::Value::Long',      as 'Cfn::Value';
  subtype 'Cfn::Value::String',    as 'Cfn::Value';
  subtype 'Cfn::Value::Double',    as 'Cfn::Value';
  subtype 'Cfn::Value::Timestamp', as 'Cfn::Value';
  subtype 'Cfn::Value::Json',      as 'Cfn::Value';

  coerce 'Cfn::Value::Boolean',
    from 'Int', via {
      my $val = $_;

      if ($val == 1) {
        Cfn::Boolean->new( Value => 1, stringy => 0 );
      } elsif($val == 0) {
        Cfn::Boolean->new( Value => 0, stringy => 0 );
      } else {
        die "Cannot convert $val to an boolean value";
      }
    },
    from 'Str', via {
      my $val = $_;
      if (lc($val) eq 'false') {
        Cfn::Boolean->new( Value => 0, stringy => 1 );
      } elsif (lc($val) eq 'true') {
        Cfn::Boolean->new( Value => 1, stringy => 1 );
      } else {
        die "Cannot convert string $val to a boolean value";
      }
    },
    from 'Object', via {
      my $val = $_;

      die "Cannot coerce a boolean from a non JSON::PP::Boolean" if (not $val->isa('JSON::PP::Boolean'));
      if ($val == 1) {
        Cfn::Boolean->new( Value => 1, stringy => 0 );
      } elsif($val == 0) {
        Cfn::Boolean->new( Value => 0, stringy => 0 );
      } else {
        die "Cannot convert $val to an boolean value";
      }
    },
    from 'HashRef', via \&coerce_hashref_to_function;

  coerce 'Cfn::Value::Integer',
    from 'Int',  via { Cfn::Integer->new( Value => $_ ) },
    from 'HashRef', via \&coerce_hashref_to_function;

  coerce 'Cfn::Value::Long',
    from 'Num',  via { Cfn::Long->new( Value => $_ ) },
    from 'HashRef', via \&coerce_hashref_to_function;

  coerce 'Cfn::Value::String',
    from 'Str',  via { Cfn::String->new( Value => $_ ) },
    from 'HashRef', via \&coerce_hashref_to_function;

  coerce 'Cfn::Value::Double',
    from 'Num',  via { Cfn::Double->new( Value => $_ ) },
    from 'HashRef', via \&coerce_hashref_to_function;

  coerce 'Cfn::Value::Timestamp',
    from 'Num',  via { Cfn::Timestamp->new( Value => $_ ) },
    from 'HashRef', via \&coerce_hashref_to_function;

  subtype 'Cfn::Value::Json',
    as 'Cfn::Value::Hash';

  coerce 'Cfn::Value::Array',
    from 'HashRef',  via (\&coerce_hash),
    from 'ArrayRef', via (\&coerce_array);

  coerce 'Cfn::Value::ArrayOfPrimitives',
    from 'HashRef',  via (\&coerce_hash),
    from 'ArrayRef', via (\&coerce_array);

  coerce 'Cfn::Value::Hash',
    from 'HashRef',  via (\&coerce_hash);

  subtype 'Cfn::Transform',
       as 'ArrayRef[Str]';

  coerce 'Cfn::Transform',
    from 'ArrayRef', via {
      return $_;
    };
  coerce 'Cfn::Transform',
    from 'Value', via {
      return [ $_ ];
    };

  subtype 'Cfn::MappingHash',
    as 'HashRef[Cfn::Mapping]';

  my $cfn_mapping_constraint = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Mapping');

  coerce 'Cfn::MappingHash',
    from 'HashRef',  via {
      my $original = $_;
      return { map { ($_ =>  $cfn_mapping_constraint->coerce($original->{ $_ }) ) } keys %$original };
    };

  coerce 'Cfn::Mapping',
    from 'HashRef',  via {
      return Cfn::Mapping->new(Map => $_);
    };

  subtype 'Cfn::OutputHash',
    as 'HashRef[Cfn::Output]';

  my $cfn_output_constraint = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Output');
  coerce 'Cfn::OutputHash',
    from 'HashRef',  via {
      my $original = $_;
      return { map { ($_ =>  $cfn_output_constraint->coerce($original->{ $_ }) ) } keys %$original };
    };

  coerce 'Cfn::Output',
    from 'HashRef',  via {
      return Cfn::Output->new(%$_);
    };

  subtype 'Cfn::ConditionHash',
    as 'HashRef[Cfn::Value]';

  my $cfn_value_constraint = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value');
  coerce 'Cfn::ConditionHash',
    from 'HashRef',  via {
      my $original = $_;
      return { map { ($_ =>  $cfn_value_constraint->coerce($original->{ $_ }) ) } keys %$original };
    };

  subtype 'Cfn::ParameterHash',
    as 'HashRef[Cfn::Parameter]';

  my $cfn_parameter_constraint = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Parameter');
  coerce 'Cfn::ParameterHash',
    from 'HashRef',  via {
      my $original = $_;
      return { map { ($_ =>  $cfn_parameter_constraint->coerce($original->{ $_ }) ) } keys %$original };
    };

  coerce 'Cfn::Parameter',
    from 'HashRef',  via {
      return Cfn::Parameter->new(%$_);
    };

  subtype 'Cfn::ResourceHash',
    as 'HashRef[Cfn::Resource]';

  my $cfn_resource_constraint = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource');
  coerce 'Cfn::ResourceHash',
    from 'HashRef',  via {
      my $original = $_;
      return { map { ($_ =>  $cfn_resource_constraint->coerce($original->{ $_ }) ) } keys %$original };
    };

  coerce 'Cfn::Resource',
    from 'HashRef',  via {
      my $type = $_->{Type};
      die "Can't coerce HashRef into a Cfn::Resource if it doesn't have a Type key" if (not defined $type);
      my $class_type = ($type =~ m/^Custom\:\:/) ? "AWS::CloudFormation::CustomResource" : $type;

      Cfn->load_resource_module($class_type);
      return "Cfn::Resource::$class_type"->new(
        %$_
      );
    };

  subtype 'Cfn::MetadataHash',
    as 'HashRef[Cfn::Value]';

  coerce 'Cfn::MetadataHash',
    from 'HashRef',  via {
      my $original = $_;
      return { map { ($_ =>  $cfn_value_constraint->coerce($original->{ $_ }) ) } keys %$original };
    };

  coerce 'Cfn::Value::Json',
    from 'HashRef',  via (\&coerce_hash);

  enum 'Cfn::Parameter::Type', [
    'String',
    'Number',
    'List<Number>',
    'CommaDelimitedList',
    'AWS::EC2::AvailabilityZone::Name',
    'List<AWS::EC2::AvailabilityZone::Name>',
    'AWS::EC2::Instance::Id',
    'List<AWS::EC2::Instance::Id>',
    'AWS::EC2::Image::Id',
    'List<AWS::EC2::Image::Id>',
    'AWS::EC2::KeyPair::KeyName',
    'AWS::EC2::SecurityGroup::GroupName',
    'List<AWS::EC2::SecurityGroup::GroupName>',
    'AWS::EC2::SecurityGroup::Id',
    'List<AWS::EC2::SecurityGroup::Id>',
    'AWS::EC2::Subnet::Id',
    'List<AWS::EC2::Subnet::Id>',
    'AWS::EC2::Volume::Id',
    'List<AWS::EC2::Volume::Id>',
    'AWS::EC2::VPC::Id',
    'List<AWS::EC2::VPC::Id>',
    'AWS::Route53::HostedZone::Id',
    'List<AWS::Route53::HostedZone::Id>',
    'AWS::SSM::Parameter::Name',
    'AWS::SSM::Parameter::Value<String>',
    'AWS::SSM::Parameter::Value<List<String>>',
    'AWS::SSM::Parameter::Value<CommaDelimitedList>',
    'AWS::SSM::Parameter::Value<AWS::EC2::AvailabilityZone::Name>',
    'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>',
    'AWS::SSM::Parameter::Value<AWS::EC2::Instance::Id>',
    'AWS::SSM::Parameter::Value<AWS::EC2::SecurityGroup::GroupName>',
    'AWS::SSM:;Parameter::Value<AWS::EC2::SecurityGroup::Id>',
    'AWS::SSM::Parameter::Value<AWS::EC2::Subnet::Id>',
    'AWS::SSM::Parameter::Value<AWS::EC2::Volume::Id>',
    'AWS::SSM::Parameter::Value<AWS::EC2::VPC::Id>',
    'AWS::SSM::Parameter::Value<AWS::Route53::HostedZone::Id>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::AvailabilityZone::Name>>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::Image::Id>>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::Instance::Id>>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::SecurityGroup::GroupName>>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::SecurityGroup::Id>>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::Subnet::Id>>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::Volume::Id>>',
    'AWS::SSM::Parameter::Value<List<AWS::EC2::VPC::Id>>',
    'AWS::SSM::Parameter::Value<List<AWS::Route53::HostedZone::Id>>',
  ];

  subtype 'ArrayOfCfn::Resource::Properties::TagType',
    as 'Cfn::Value',
    where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
    message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

  coerce 'ArrayOfCfn::Resource::Properties::TagType',
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
          Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::TagType')->coerce($_)
        } @$_
      ]);
    };

  subtype 'Cfn::Resource::Properties::TagType',
    as 'Cfn::Value';

  coerce 'Cfn::Resource::Properties::TagType',
    from 'HashRef',
    via {
      if (my $f = Cfn::TypeLibrary::try_function($_)) {
        return $f
      } else {
        return Cfn::Resource::Properties::Tag->new( %$_ );
      }
    };

  enum 'Cfn::PseudoParameterValue', [
    'AWS::AccountId',
    'AWS::NotificationARNs',
    'AWS::NoValue',
    'AWS::Partition',
    'AWS::Region',
    'AWS::StackId',
    'AWS::StackName',
    'AWS::URLSuffix',
  ];

  coerce 'Cfn::Internal::Options',
    from 'HashRef',
    via { Cfn::Internal::Options->new(%$_) };
};

package Cfn::Value {
  use Moose;
  # just a base class for everything that can go into a cloudformation
  # object
  sub as_hashref { shift->Value->as_hashref(@_) }
}

package Cfn::DynamicValue {
  use Moose;
  use Scalar::Util qw/blessed/;
  extends 'Cfn::Value';
  has Value => (isa => 'CodeRef', is => 'rw', required => 1);

  sub to_value {
    my $self = shift;
    return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($self->resolve_value(@_));
  }

  sub _resolve_value {
    my ($v, $args) = @_;
    if (blessed($v) and $v->isa('Cfn::Value')) {
      return $v->as_hashref(@$args);
    } elsif (not blessed($v) and ref($v) eq 'HASH') {
      return { map { ($_ => _resolve_value($v->{ $_ })) } keys %$v }
    } elsif (not blessed($v) and ref($v) eq 'ARRAY') {
      return [ map { _resolve_value($_) } @$v ]
    } else {
      return $v
    }
  }

  sub resolve_value {
    my $self = shift;
    my @args = reverse @_;
    my (@ret) = ($self->Value->(@args));
    @ret = map { _resolve_value($_, \@args) } @ret;
    return (@ret);
  }

  override as_hashref => sub {
    my $self = shift;
    return $self->resolve_value(@_);
  };
}

package Cfn::Value::Function {
  use Moose;
  extends 'Cfn::Value';
  has Function => (isa => 'Str', is => 'rw', required => 1);
  has Value => (isa => 'Cfn::Value', is => 'rw', required => 1, coerce => 1);

  sub as_hashref {
    my $self = shift;
    my $key = $self->Function;
    return { $key => $self->Value->as_hashref(@_) }
  }

  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    die "Can't path $part into a $self" if ($part ne $self->Function);
    return $self->Value->path_to($rest) if (defined $rest);
    return $self->Value;
  }
}

package Cfn::Value::TypedValue {
  use Moose;
  extends 'Cfn::Value';

  sub as_hashref {
    my $self = shift;
    my $hr = { map  { ( $_->[0] => $_->[1]->as_hashref(@_) ) }
               grep { defined $_->[1]  }
               map { [ $_->name, $_->get_value($self) ] }
               $self->meta->get_all_attributes
             };
    return $hr;
  }

  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    die "Can't go into $part on $self" if (not $self->can($part));
    return $self->$part->path_to($rest) if (defined $rest);
    return $self->$part;
  }
}

package Cfn::Value::Function::Condition {
  use Moose;
  extends 'Cfn::Value::Function';
  has Value => (isa => 'Cfn::Value', is => 'rw', required => 1, coerce => 1);

  sub Condition {
    shift->Value->Value;
  }
}

package Cfn::Value::Function::Ref {
  use Moose;
  extends 'Cfn::Value::Function';
  has Value => (isa => 'Cfn::Value', is => 'rw', required => 1, coerce => 1);

  sub LogicalId {
    shift->Value->Value;
  }
}

package Cfn::Value::Function::PseudoParameter {
  use Moose;
  extends 'Cfn::Value::Function::Ref';
}

package Cfn::Value::Function::GetAtt {
  use Moose;
  extends 'Cfn::Value::Function';
  has Value => (isa => 'Cfn::Value::ArrayOfPrimitives', is => 'rw', required => 1, coerce => 1);

  sub LogicalId {
    my $self = shift;
    $self->Value->Value->[0]->Value;
  }

  sub Property {
    my $self = shift;
    $self->Value->Value->[1]->Value;
  }
}


package Cfn::Value::Array {
  use Moose;
  extends 'Cfn::Value';
  has Value => (
    is => 'rw',
    required => 1,
    isa => 'ArrayRef[Cfn::Value|Cfn::Resource::Properties]',
    traits => ['Array'],
    handles => {
      'Count' => 'count',
    }
  );

  sub as_hashref {
    my $self = shift;
    my @args = @_;
    return [ map { $_->as_hashref(@args)  } @{ $self->Value } ]
  }

  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    die "Can't go into $part on $self" if (not exists $self->Value->[ $part ]);
    return $self->Value->[ $part ]->path_to($rest) if (defined $rest);
    return $self->Value->[ $part ];
  }
}

package Cfn::Value::Hash {
  use Moose;
  extends 'Cfn::Value';
  has Value => (
    is => 'rw',
    required => 1,
    isa => 'HashRef[Cfn::Value]',
  );

  override as_hashref => sub {
    my $self = shift;
    my @args = @_;
    return { map { $_ => $self->Value->{$_}->as_hashref(@args) } keys %{ $self->Value } };
  };

  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    die "Can't go into $part on $self" if (not exists $self->Value->{ $part }); 
    return $self->Value->{ $part }->path_to($rest) if (defined $rest);
    return $self->Value->{ $part };
  }
}



package Cfn::Value::Primitive {
  use Moose;
  extends 'Cfn::Value';
  has Value => (isa => 'Value', is => 'rw', required => 1);
  override as_hashref => sub {
    my $self = shift;
    return $self->Value;
  }
}

package Cfn::Boolean {
  use Moose;
  use JSON;
  extends 'Cfn::Value::Primitive';
  has '+Value' => (isa => 'Bool');
  has stringy => (is => 'ro', required => 1, isa => 'Bool');
  override as_hashref => sub {
    my $self = shift;
    if ($self->stringy){
      return ($self->Value)?'true':'false';
    } else {
      return ($self->Value)?JSON->true:JSON->false;
    }
  }
}

package Cfn::Integer {
  use Moose;
  extends 'Cfn::Value::Primitive';
  has '+Value' => (isa => 'Int');
}

package Cfn::Long {
  use Moose;
  extends 'Cfn::Value::Primitive';
  has '+Value' => (isa => 'Num');
}

package Cfn::String {
  use Moose;
  extends 'Cfn::Value::Primitive';
  has '+Value' => (isa => 'Str');
}

package Cfn::Double {
  use Moose;
  extends 'Cfn::Value::Primitive';
  has '+Value' => (isa => 'Num');
}

package Cfn::Timestamp {
  use Moose;
  extends 'Cfn::Value::Primitive';
  has '+Value' => (isa => 'Str');
}

package Cfn::Resource {
  use Moose;
  # CCfnX::Dependencies is not production ready
  with 'Cfn::Dependencies';

  sub BUILD {
    my $self = shift;

    my $class_name = $self->meta->name;
    $class_name =~ s/^Cfn::Resource:://;

    # If the user is forcing the Type we want to validate
    # that we ended up with a valid object
    if (defined $self->Type) {
       if ($class_name ne $self->Type and $class_name ne 'AWS::CloudFormation::CustomResource') {
         die "Invalid Cfn::Resource"
       }
    } else {
      $self->Type($class_name);
    }
  }

  has Type => (isa => 'Str', is => 'rw');
  has Properties => (isa => 'Cfn::Resource::Properties', is => 'rw');
  has DeletionPolicy => (isa => 'Cfn::Resource::DeletionPolicy', is => 'rw');
  has DependsOn => (isa => 'ArrayRef[Str]|Str', is => 'rw');
  has Condition => (isa => 'Str', is => 'rw');

  sub Property {
    my ($self, $property) = @_;
    return undef if (not defined $self->Properties);
    return $self->Properties->$property;
  }

  sub hasAttribute {
    my ($self, $attribute) = @_;
    my @matches = grep { $_ eq $attribute } @{ $self->AttributeList };
    return @matches == 1;
  }

  sub DependsOnList {
    my $self = shift;
    return () if (not defined $self->DependsOn);
    return @{ $self->DependsOn } if (ref($self->DependsOn) eq 'ARRAY');
    return $self->DependsOn;
  }

  has Metadata => (isa => 'Cfn::Value::Hash', is => 'rw', coerce => 1);
  has UpdatePolicy => (isa => 'Cfn::Resource::UpdatePolicy', is => 'rw', coerce => 1);
  has CreationPolicy => (isa => 'HashRef', is => 'rw');
  has UpdateReplacePolicy => (isa => 'Cfn::Resource::UpdateReplacePolicy', is => 'rw');

  sub as_hashref {
    my $self = shift;
    my @args = @_;
    return {
      (map { $_ => $self->$_->as_hashref(@args) }
        grep { defined $self->$_ } qw/Properties Metadata UpdatePolicy/),
      (map { $_ => $self->$_ }
        grep { defined $self->$_ } qw/Type DeletionPolicy UpdateReplacePolicy DependsOn CreationPolicy Condition/),
    }
  }

  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    if      ($part eq 'Properties') {
      return $self->Properties if (not defined $rest);
      return $self->Properties->path_to($rest);
    } elsif ($part eq 'Metadata') {
      return $self->Metadata if (not defined $rest);
      return $self->Metadata->{ $rest };
    } elsif ($part eq 'DependsOn') {
      return $self->DependsOn if (not defined $rest);
      die "Can't go into $path on resource";
    } elsif ($part eq 'Type' or $path eq 'Condition') {
      return $self->$part if (not defined $rest);
      die "Can't go into $path on resource";
    } else {
      die "Can't go into $path on resource";
    }
  }
}

package Cfn::Resource::Properties {
  use Moose;
  sub as_hashref {
    my $self = shift;
    my @args = @_;

    my $ret = {};
    foreach my $att ($self->meta->get_all_attributes) {
      my $el = $att->name;
      if (defined $self->$el) {
        my @ret = $self->$el->as_hashref(@args);
        if (@ret == 1) {
          $ret->{ $el } = $ret[0];
        } else {
          die "A property returned an odd number of values";
        }
      }
    }
    return $ret;
  }

  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    die "Can't go into $part on $self" if (not $self->can($part));
    return $self->$part->path_to($rest) if (defined $rest);
    return $self->$part;
  }

  sub resolve_references_to_logicalid_with {
    my ($self, $logical_id, $object) = @_;
    foreach my $att ($self->meta->get_attribute_list) {
      next if (not defined $self->$att);

      if      ($self->$att->isa('Cfn::Value::Function::Ref')    and $self->$att->LogicalId eq $logical_id) {
        my $func = $self->$att;
        #$self->$att('TBD');   #$object->$objects_ref_prop
        #warn "Resolved TBD $logical_id";
        my @attrs = $object->meta->get_all_attributes;
        my @ref = grep { $_->does('CCfnX::Meta::Attribute::Trait::RefValue') } @attrs;
        if (not @ref) { die $object . " has no RefValue trait. Cannot resolve Ref" }
        else {
          my $property = $ref[0]->name;
          my $value = $object->$property;
          $self->$att($value);
        }
      } elsif ($self->$att->isa('Cfn::Value::Function::GetAtt') and $self->$att->LogicalId eq $logical_id) {
        my $func = $self->$att;
        my $property = $func->Property;
        $self->$att($object->$property);
        warn "Resolved $logical_id $property";
      } elsif ($self->$att->isa('Cfn::Value::Array')) {
        map { resolve_references_to_logicalid_with($_, $logical_id, $object) } @{ $self->$att->Value };
      } elsif ($self->$att->isa('Cfn::Value::Function')) {
        resolve_references_to_logicalid_with($self->$att, $logical_id, $object);
      } elsif ($self->$att->isa('Cfn::Value::Primitive')) {
        # End case. Primitives do nothing
        # This case is important to be here, as it filters out any Primitives for
        # the next if
      } elsif ($self->$att->isa('Cfn::Value')) {
        resolve_references_to_logicalid_with($self->$att, $logical_id, $object);
      } else {
        die "Don't know how to resolve $att on " . $self->$att;
      }
    }
  }
}

package Cfn::Resource::UpdatePolicy {
  use Moose;
  extends 'Cfn::Value::TypedValue';
  has AutoScalingReplacingUpdate => (isa => 'Cfn::Resource::UpdatePolicy::AutoScalingReplacingUpdate', is => 'rw', coerce => 1);
  has AutoScalingRollingUpdate => (isa => 'Cfn::Resource::UpdatePolicy::AutoScalingRollingUpdate', is => 'rw', coerce => 1);
  has AutoScalingAutoScalingScheduledAction => (isa => 'Cfn::Resource::UpdatePolicy::AutoScalingScheduledAction', is => 'rw', coerce => 1);
  has UseOnlineResharding => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1);
}

package Cfn::Resource::UpdatePolicy::AutoScalingReplacingUpdate {
  use Moose;
  extends 'Cfn::Value::TypedValue';
  has WillReplace => (isa => 'Cfn::Value::Boolean', is => 'rw', required => 1, coerce => 1);
}

package Cfn::Resource::UpdatePolicy::AutoScalingRollingUpdate {
  use Moose;
  extends 'Cfn::Value::TypedValue';
  has MaxBatchSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1);
  has MinInstancesInService => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1);
  has MinSuccessfulInstancesPercent => (isa => 'Cfn::Value::Integer', is =>  'rw', coerce => 1);
  has PauseTime => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1);
  # TODO: better validate SuspendProcesses
  has SuspendProcesses => (isa => 'Cfn::Resource::UpdatePolicy::AutoScalingRollingUpdate::SuspendProcesses', is => 'rw', coerce => 1);
  has WaitOnResourceSignals => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1);
}

package Cfn::Resource::UpdatePolicy::AutoScalingScheduledAction {
  use Moose;
  extends 'Cfn::Value::TypedValue';
  has IgnoreUnmodifiedGroupSizeProperties => (isa => 'Cfn::Value::Boolean', is => 'rw', required => 1, coerce => 1);
}

package Cfn::Output {
  use Moose;
  has Value => (isa => 'Cfn::Value', is => 'rw', required => 1, coerce => 1);
  has Description => (isa => 'Str', is => 'rw');
  has Condition => (isa => 'Str', is => 'rw');
  has Export => (isa => 'Cfn::Value::Hash', is => 'rw', coerce => 1);
  sub as_hashref {
    my $self = shift;
    my @args = @_;
    return {
      Value => $self->Value->as_hashref(@args),
      (defined $self->Condition) ? (Condition => $self->Condition) : (),
      (defined $self->Description) ? (Description => $self->Description) : (),
      (defined $self->Export) ? (Export => $self->Export->as_hashref) : (),
    }
  }
  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    die "Can't path into $part on $self" if ($part ne 'Value' and
                                             $part ne 'Description' and
                                             $part ne 'Condition' and
                                             $part ne 'Export'
                                            );
    if ($part eq 'Value') {
      return $self->Value if (not defined $rest);
      return $self->Value->path_to($rest);
    } elsif ($part eq 'Description' or $part eq 'Condition') {
      die "Can't path into $part on $self" if (defined $rest);
      return $self->$part;
    } elsif ($part eq 'Export') {
      return $self->Export if (not defined $rest);
      return $self->Value->path_to($rest);
    }

  } 
}

package Cfn::Parameter {
  use Moose;
  has Type => (isa => 'Cfn::Parameter::Type', is => 'ro', required => 1);
  has Default => (isa => 'Str', is => 'rw');
  has NoEcho => (isa => 'Str', is => 'rw');
  has AllowedValues  => ( isa => 'ArrayRef[Str]', is => 'rw');
  has AllowedPattern  => ( isa => 'Str', is => 'rw');
  has MaxLength  => ( isa => 'Str', is => 'rw');
  has MinLength  => ( isa => 'Str', is => 'rw');
  has MaxValue  => ( isa => 'Str', is => 'rw');
  has MinValue  => ( isa => 'Str', is => 'rw');
  has Description  => ( isa => 'Str', is => 'rw');
  has ConstraintDescription  => ( isa => 'Str', is => 'rw');

  sub as_hashref {
    my $self = shift;
    return {
      map { (defined $self->$_) ? ($_ => $self->$_) : () }
      qw/Type Default NoEcho AllowedValues AllowedPattern MaxLength
      MinLength MaxValue MinValue Description ConstraintDescription/,
    }
  }
}

package Cfn::Mapping {
  use Moose;
  has Map => (isa => 'HashRef', is => 'ro');

  sub as_hashref {
    my $self = shift;
    return $self->Map;
  }
}

package Cfn::Internal::Options {
  use Moose;
  has custom_resource_rename => (is => 'rw', isa => 'Bool', default => 0);
}

package Cfn {
  use Moose;
  use Moose::Util;
  use Scalar::Util;
  use Cfn::ResourceModules;

  has AWSTemplateFormatVersion => (isa => 'Str', is => 'rw');
  has Description => (isa => 'Str', is => 'rw');
  has Transform => (isa => 'Cfn::Transform', is => 'rw', coerce => 1);

  our $VERSION = '0.14';

  has Parameters => (
    is => 'rw',
    isa => 'Cfn::ParameterHash',
    coerce => 1,
    traits => [ 'Hash' ],
    handles => {
      Parameter => 'accessor',
      ParameterList => 'keys',
      ParameterCount => 'count',
      ParameterList => 'keys',
    },
  );
  has Mappings => (
    is => 'rw',
    isa => 'Cfn::MappingHash',
    coerce => 1,
    traits => [ 'Hash' ],
    handles => {
      Mapping => 'accessor',
      MappingCount => 'count',
      MappingList => 'keys',
    },
  );
  has Conditions => (
    is => 'rw',
    isa => 'Cfn::ConditionHash',
    traits  => [ 'Hash' ],
    coerce => 1,
    handles => {
      Condition => 'accessor',
      ConditionList => 'keys',
      ConditionCount => 'count',
    },
  );
  has Resources => (
    is      => 'rw',
    isa     => 'Cfn::ResourceHash',
    coerce => 1,
    traits  => [ 'Hash' ],
    handles => {
      Resource => 'accessor',
      ResourceList => 'keys',
      ResourceCount => 'count',
    },
  );
  has Outputs => (
    is      => 'rw',
    isa     => 'Cfn::OutputHash',
    coerce  => 1,
    traits  => [ 'Hash' ],
    handles => {
      Output => 'accessor',
      OutputList => 'keys',
      OutputCount => 'count',
    },
  );
  has Metadata => (
    is      => 'rw',
    isa     => 'Cfn::MetadataHash',
    coerce  => 1,
    traits  => [ 'Hash' ],
    handles => {
      MetadataItem => 'accessor',
      MetadataList => 'keys',
      MetadataCount => 'count',
    },
  );

  has cfn_options => (
    is => 'ro',
    isa => 'Cfn::Internal::Options',
    coerce => 1,
    default => sub { Cfn::Internal::Options->new },
  );

  sub list_resource_modules {
    return Cfn::ResourceModules::list();
  }

  sub load_resource_module {
    my (undef, $type) = @_;
    return Cfn::ResourceModules::load($type);
  }

  sub ResourcesOfType {
    my ($self, $type) = @_;
    return grep { $_->Type eq $type } values %{ $self->Resources };
  }

  sub addParameter {
    my ($self, $name, $type, %rest) = @_;
    Moose->throw_error("A parameter named $name already exists") if (defined $self->Parameter($name));
    if (ref $type) {
      return $self->Parameter($name, $type);
    } else {
      return $self->Parameter($name, Cfn::Parameter->new(Type => $type, %rest));
    }
  }

  sub addMapping {
    my ($self, $name, $mapping) = @_;
    Moose->throw_error("A mapping named $name already exists") if (defined $self->Mapping($name));
    if (ref $mapping eq 'HASH') {
      return $self->Mapping($name, Cfn::Mapping->new(Map => $mapping));
    } else {
      return $self->Mapping($name, $mapping);
    }
  }

  sub addOutput {
    my ($self, $name, $output, @rest) = @_;
    Moose->throw_error("An output named $name already exists") if (defined $self->Output($name));
    if (my $class = blessed $output) {
      die "Can't call addOutput with a $class" if ($class ne 'Cfn::Output');
      return $self->Output($name, $output);
    } else {
      return $self->Output($name, Cfn::Output->new( Value => $output, @rest ));
    }
  }

  sub addCondition {
    my ($self, $name, $value) = @_;
    Moose->throw_error("A condition named $name already exists") if (defined $self->Condition($name));
    return $self->Condition($name, Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($value));
  }

  sub addResource {
    my ($self, $name, $second_param, $third_param, @rest) = @_;
    Moose->throw_error("A resource named $name already exists") if (defined $self->Resource($name));

    if (not ref $second_param){
      my $type = $second_param;
      my (@properties, @extra_props);

      if (ref($third_param) eq 'HASH') {
        @properties = %$third_param;
        if (not defined $rest[0]){
          @extra_props = ();
        } elsif (defined $rest[0] and ref($rest[0]) eq 'HASH') {
          @extra_props = %{ $rest[0] }
        } else {
          die "Don't know what to do with the fourth parameter to addResource";
        }
      } else {
        @properties = ( $third_param // () , @rest);
        @extra_props = ();
      }

      return $self->Resources->{ $name } = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource')->coerce({
          Type => $type,
          Properties => { @properties },
          @extra_props,
        })
    } else {
      my $object = $second_param;
      return $self->Resource($name, $object);
    }
  }

  sub addMetadata {
    my ($self, $name, $metadata) = @_;

    if (ref($name) eq 'HASH') {
      Moose->throw_error("The stack already has metadata") if (defined $self->Metadata);
      $self->Metadata($name);
    } else {
      Moose->throw_error("A metadata item named $name already exists") if (defined $self->MetadataItem($name));
      return $self->MetadataItem($name, Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($metadata));
    }
  }

  sub addResourceMetadata {
    my ($self, $name, %args) = @_;
    Moose->throw_error("A resource named $name must already exist") if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->Metadata({ %args });
  }
  sub addDependsOn {
    my ($self, $name, @args) = @_;
    Moose->throw_error("A resource named $name must already exist") if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->DependsOn( [ @args ] );
  }
  sub addDeletionPolicy {
    my ($self, $name, $policy) = @_;
    Moose->throw_error("A resource named $name must already exist") if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->DeletionPolicy( $policy );
  }
  sub addUpdatePolicy {
    my ($self, $name, $policy) = @_;
    Moose->throw_error("A resource named $name must already exist") if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->UpdatePolicy( Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource:UpdatePolicy')->coerce($policy) );
  }

  sub addTransform {
    my ($self, $name, $transform) = @_;
    if ( not defined $self->Transform) { $self->Transform([]) };
    push @{$self->Transform}, @{$transform};
  }

  sub from_hashref {
    my ($class, $hashref) = @_;
    return $class->new(%$hashref);
  }

  sub resolve_dynamicvalues {
    my $self = shift;
    return Cfn->from_hashref($self->as_hashref);
  }

  sub as_hashref {
    my $self = shift;
    return {
      (defined $self->AWSTemplateFormatVersion)?(AWSTemplateFormatVersion => $self->AWSTemplateFormatVersion):(),
      (defined $self->Description)?(Description => $self->Description):(),
      (defined $self->Transform) ? (Transform => $self->Transform) : (),
      (defined $self->Mappings)?(Mappings => { map { ($_ => $self->Mappings->{ $_ }->as_hashref) } keys %{ $self->Mappings } }):(),
      (defined $self->Parameters)?(Parameters => { map { ($_ => $self->Parameters->{ $_ }->as_hashref) } keys %{ $self->Parameters } }):(),
      (defined $self->Outputs)?(Outputs => { map { ($_ => $self->Outputs->{ $_ }->as_hashref($self)) } keys %{ $self->Outputs } }):(),
      (defined $self->Conditions)?(Conditions => { map { ($_ => $self->Condition($_)->as_hashref($self)) } $self->ConditionList }):(),
      (defined $self->Metadata)?(Metadata => { map { ($_ => $self->Metadata->{ $_ }->as_hashref($self)) } $self->MetadataList }):(),
      Resources => { map { ($_ => $self->Resource($_)->as_hashref($self)) } $self->ResourceList },
    }
  }

  sub path_split {
    my $path = shift;
    die "No path specified" if (not defined $path);
    my @parts = split/\./, $path, 2;
    return ($parts[0], $parts[1]);
  }

  sub path_to {
    my ($self, $path) = @_;
    my ($part, $rest) = Cfn::path_split($path);

    die "Can't path into $part" if ($part ne 'Resources' and
                                    $part ne 'Mappings' and
                                    $part ne 'Parameters' and
                                    $part ne 'Outputs' and
                                    $part ne 'Conditions' and
                                    $part ne 'Metadata');

    my $current_element = $self->$part;
    return $current_element if (not defined $rest);

    ($part, $rest) = Cfn::path_split($rest);

    die "Must specify a resource to traverse into" if (not defined $part);

    die "No element $part found" if (not defined $current_element->{ $part });
    return $current_element->{ $part }->path_to($rest) if (defined $rest);
    return $current_element->{ $part };
  }

  has json => (is => 'ro', lazy => 1, default => sub {
      require JSON;
      return JSON->new->canonical
    });

  sub as_json {
    my $self = shift;
    my $href = $self->as_hashref;
    return $self->json->encode($href);
  }

  sub from_json {
    my ($class, $json) = @_;

    require JSON;
    return $class->from_hashref(JSON::from_json($json));
  }

  sub _get_yaml_pp {
    require YAML::PP;
    YAML::PP->new(
      schema => [ ':Cfn::YAML::Schema' ],
    );
  }

  has yaml => (is => 'ro', lazy => 1, default => \&_get_yaml_pp);

  sub as_yaml {
    my $self = shift;
    return $self->yaml->dump_string($self);
  }

  sub from_yaml {
    my ($class, $yaml) = @_;
    my $parser = _get_yaml_pp;
    return $class->from_hashref($parser->load_string($yaml));
  }
}

package Cfn::MutabilityTrait {
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('CfnMutability');
  has mutability => (is => 'ro', isa => 'Str', required => 1);
}

package Cfn::Resource::Properties::Tag {
  use Moose;
  extends 'Cfn::Value::TypedValue';
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn - An object model for CloudFormation documents

=head1 DESCRIPTION

This module helps parse, manipulate, validate and generate CloudFormation documents in JSON
and YAML formats (see stability section for more information on YAML). It creates an object 
model of a CloudFormation template so you can work with the document as a set of objects. 
See L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html> for
more information.

It provides full blown objects for all know CloudFormation resources. See 
L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html> for a list
of all resource types. These objects live in the C<Cfn::Resource> namespace.

The module provides a set of objects representing each piece of CloudFormation. Following is a list of all
object types in the distribution:

=head1 Cfn object

The C<Cfn> class is the "root" of a CloudFormation document. It represents an entire CloudFormation document.
It has attributes and methods to access the parts of a CloudFormation document.

  use Cfn;
  my $cfn = Cfn->new;
  $cfn->addResource('MyRes' => ...);
  my $res = $cfn->Resource('MyRes');

=head2 Constructors

=head3 new(Resources => { ... }, Outputs => { }, ...)

The default Moose constructor. You can initialize an empty document like this:

  my $cfn = Cfn->new;
  print $cfn->as_json;

=head3 from_hashref

CloudFormation documents resemble Perl HashRefs (since they're just JSON datastructures).
This method converts a hashref that represents a CloudFormation document into a Cfn object.

  use Data::Dumper;
  my $cfn = Cfn->from_hashref({ Resources => { R1 => { Type => '...', Properties => { ... } } } });
  print Dumper($cfn->Resource('R1');

=head3 from_json

This method creates a Cfn object from a JSON string that contains a CloudFormation document in JSON format

=head3 from_yaml

This method creates a Cfn object from a YAML string that contains a CloudFormation document in YAML format

=head2 Attributes

=head3 json

When serializing to JSON with C<as_json>, the encode method on this object is called passing the
documents hashref representation. By default the JSON generated is "ugly", that is, all in one line,
but in canonical form (so a given serialization always has attributes in the same order).

You can specify your own JSON serializer to control how JSON is generated:

  my $cfn = Cfn->new(json => JSON->new->canonical->pretty);
  ...
  print $cfn->as_json;

=head3 yaml

Holds a configured C<YAML::PP> parser for use when serializing and deserializing to and from YAML.
Methods C<load_string> and C<dump_string> are called when needed from convert the object model
to a YAML document, and to convert a YAML document to a datastructure that can later be coerced
into the object model.

=head3 cfn_options

A C<Cfn::Internal::Options> object instance that controls how the as_hashref method converts the Cfn object
to a datastructure suitable for CloudFormation (only HashRefs, ArrayRefs and Scalars).

You can specify your own options as a hashref with the attributes to C<Cfn::Internal::Options> in the
constructor.

  my $cfn = Cfn->new(cfn_options => { custom_resource_rename => 1 });
  ...
  print Dumper($cfn->as_hashref);

See the C<Cfn::Internal::Options> object for more details

=head3 AWSTemplateFormatVersion

A string with the value of the AWSTemplateFormatVersion field of the CloudFormation document. Can be undef.

=head3 Description

A string with the value of the Description field of the CloudFormation document. Can be undef.

=head3 Transform

An ArrayRef of Strings with the values of the Transform field of the CloudFormation document. Can be undef.

=head3 Parameters

A HashRef of C<Cfn::Parameter> objects. The keys are the name of the Parameters. 
There are a set of convenience methods for accessing this attribute:

  $cfn->Parameter('ParamName') # returns a Cfn::Parameter or undef
  $cfn->ParameterList # returns a list of the parameters in the document
  $cfn->ParameterCount # returns the number of parameters in the document

=head3 Mappings

A HashRef of C<Cfn::Mapping> objects. The keys are the name of the Mappings. 
There are a set of convenience methods for accessing this attribute:

  $cfn->Mapping('MappingName') # returns a Cfn::Parameter or undef
  $cfn->MappingList # returns a list of the mappings in the document
  $cfn->MappingCount # returns the number of mappings in the document

=head3 Conditions

A HashRef of C<Cfn::Condition> objects. The keys are the name of the Mappings. 
There are a set of convenience methods for accessing this attribute:

  $cfn->Mapping('MappingName') # returns a Cfn::Mapping or undef
  $cfn->MappingList # returns a list of the mappings in the document
  $cfn->MappingCount # returns the number of mappings in the document

=head3 Resources

A HashRef of C<Cfn::Resource> objects. The keys are the name of the Resources. 
There are a set of convenience methods for accessing this attribute:

  $cfn->Resource('ResourceName') # returns a Cfn::Resource or undef
  $cfn->ResourceList # returns a list of the resources in the document
  $cfn->ResourceCount # returns the number of resources in the document

=head3 Outputs

A HashRef of C<Cfn::Output> objects. The keys are the name of the Outputs. 
There are a set of convenience methods for accessing this attribute:

  $cfn->Output('OutputName') # returns a Cfn::Output or undef
  $cfn->OutputList # returns a list of the outputs in the document
  $cfn->OutputCount # returns the number of outputs in the document

=head3 Metadata

A HashRef of C<Cfn::Value> or subclasses of C<Cfn::Value>. Represents the 
Metadata key of the CloudFormation document.

There are a set of convenience methods for accessing this attribute:

  $cfn->Metadata('MetadataName') # returns a Cfn::Metadata or undef
  $cfn->MetadataList # returns a list of keys in the document Metadata
  $cfn->MetadataCount # returns the number of keys in the document Metadata

=head2 Methods

=head3 as_hashref

Returns a Perl HashRef representation of the CloudFormation document. This HashRef
has no objects in it. It is suitable for converting to JSON and passing to CloudFormation

C<as_hashref> triggers the serialization process of the document, which scans the whole
object model asking it's components to serialize (calling their C<as_hashref>). Objects
can decide how they serialize to a hashref.

When C<$cfn->as_hashref> is invoked, all the dynamic values in the Cfn object will be 
called with the C<$cfn> instance as the first parameter to their subroutine

  $cfn->addResource('R1', 'AWS::IAM::User', Path => Cfn::DynamicValue->new(Value => sub {
    my $cfn = shift;
    return $cfn->ResourceCount + 41
  }));
  $cfn->as_hashref->{ Resources }->{ R1 }->{ Properties }->{ Path } # == 42

=head3 as_json

Returns a JSON representation of the current instance

=head3 as_yaml

Returns a YAML representation of the current instance

=head3 path_to($path)

Given a path in the format C<'Resources.R1.Properties.PropName'> it will return the value
stored in PropName of the resource R1. Use C<'Resource.R1.Properties.ArrayProp.0'> to access
Arrays.

=head3 resolve_dynamicvalues

Returns a new C<Cfn> object with all C<Cfn::DynamicValues> resolved.

=head3 ResourcesOfType($type)

Returns a list of all the Resources of a given type.

  foreach my $iam_user ($cfn->ResourcesOfType('AWS::IAM::User')) {
    ...
  }

=head3 addParameter($name, $object)

Adds an already instanced C<Cfn::Parameter> object. Throws an exception if the parameter already exists.

  $cfn->addParameter('P1', Cfn::Parameter->new(Type => 'String', MaxLength => 5));

=head3 addParameter($name, $type, %properties)

Adds a named parameter to the document with the specified type and properties. See C<Cfn::Parameter> for available
properties. Throws an exception if the parameter already exists.

  $cfn->addParameter('P1', 'String', MaxLength => 5);

=head3 addMapping($name, $object_or_hashref);

Adds a named mapping to the mappings of the document. The second parameter can be a C<Cfn::Mapping> object or 
a HashRef that will be coerced to a C<Cfn::Mapping> object

  $cfn->addMapping('amis', { 'eu-west-1' => 'ami-12345678' });
  $cfn->addMapping('amis', Cfn::Mapping->new(Map => { 'eu-west-1' => 'ami-12345678' }));
  # $cfn->Mapping('amis') is a Cfn::Mapping object

=head3 addOutput($name, $object)

Adds an already instanced C<Cfn::Output> object. Throws an exception if the output already exists.

  $cfn->addParameter('O1', Cfn::Output->new(Value => { Ref => 'R1' });

=head3 addOutput($name, $output[, %output_attributes]);

Adds a named output to the document. See C<Cfn::Output> for available
output_attributes. Throws an exception if the output already exists.

  $cfn->addParameter('O1', { Ref => 'R1' });
  $cfn->addParameter('O1', { Ref => 'R1' }, Description => 'Bla bla');


=head3 addCondition($name, $value)

Adds a named condition to the document. The value parameter should be
a HashRef that expresses a CloudFormation condition. See L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html>

=head3 addResource($name, $object)

Adds a named resource to the document. $object has to be an instance of a 
subclass of C<Cfn::Resource>. Throws an exception if a resource already
exists with that name.

=head3 addResource($name, $type, %properties)

Adds a named resource to the document, putting the specified properties in the 
resources properties. See subclasses of C<Cfn::Resource> for more details.

  $cfn->addResource('R1', 'AWS::IAM::User');

  $cfn->addResource('R2', 'AWS::IAM::User', Path => '/');
  # $cfn->Resource('R2')->Properties->Path is '/'

Throws an exception if a resource already exists with that name.

=head3 addResource($name, $name, $properties, $resource_attributes)

Adds a named resource to the document. properties and resource_attributes
are hashrefs.

  $cfn->addResource('R3', 'AWS::IAM::User', { Path => '/' });
  # $cfn->Resource('R3')->Properties->Path is '/'
  $cfn->addResource('R3', 'AWS::IAM::User', { Path => '/' }, { DependsOn => [ 'R2' ] });
  # $cfn->Resource('R3')->DependsOn->[0] is 'R2'

Throws an exception if a resource already exists with that name.

=head3 addResourceMetadata($name, %metadata);

Adds metadata to the Metadata attribute of a Resource.

  $cfn->addResourceMetadata('R1', MyMetadataKey1 => 'Value');
  # $cfn->Resource('R1')->Metadata->{ MyMedataKey1 } is 'Value'

=head3 addDependsOn($resource_name, $depends_on1, $depends_on2)

  $cfn->addDependsOn('R1', 'R2', 'R3');
  # $cfn->Resource('R1')->DependsOn is [ 'R2', 'R3' ]

=head3 addDeletionPolicy($resource_name)

  Adds a DeletionPolicy to the resource. L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html>

=head3 addUpdatePolicy($resource_name)
  
  Adds an UpdatePolicy to the resource. L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html>

=head1 Cfn::Value

Is a base class for the attributes of Cloudformation values. In Cloudformation you can find that in
a resources attributes you can place functions, references, etc.

  "Attribute": "hello"
  "Attribute": { "Ref": "R1" }
  "Attribute": { "Fn::GetAtt": [ "R1", "InstanceId" ] }

All value objects in the Cfn toolkit subclass C<Cfn::Value> as a common ancestor. Once the object model is built,
you can find that a

  $cfn->addResource('R1', 'AWS::IAM::User', Path => '/');
  # $cfn->Resource('R1')->Properties->Path is a Cfn::Value::Primitive

  $cfn->addResource('R1', 'AWS::IAM::User', Path => { 'Fn::Join' => [ '/', { Ref => 'Param1' }, '/' ] });
  # $cfn->Resource('R1')->Properties->Path is a Cfn::Value::Function::Join

All C<Cfn::Value> subclasses have to implement an C<as_hashref> method that returns a HashRef suitable for 
conversion to JSON for CloudFormation. A attributes of objects that hold C<Cfn::Value> subclasses should
enable coercion of the attribute so that plain hashrefs can be coerced into the appropiate Cfn::Value objects

Here is a Hierarchy of the different Cfn::Value descendant object:

  Cfn::Value
  |--Cfn::DynamicValue
  |--Cfn::Value::Function
  |  |--Cfn::Value::Function::Condition
  |  |--Cfn::Value::Function::Ref
  |     |--Cfn::Value::Function::PseudoParameter
  |  |--Cfn::Value::Function::GetAtt
  |--Cfn::Value::Array
  |--Cfn::Value::Hash
  |--Cfn::Value::Primitive
  |  |--Cfn::Boolean
  |  |--Cfn::Integer
  |  |--Cfn::Long
  |  |--Cfn::String
  |  |--Cfn::Double
  |  |--Cfn::Timestamp
  |--Cfn::Value::TypedValue
  

=head2 Cfn::DynamicValue

The C<Value> attribute of this object is a CodeRef that get's called
when as_hashref is called.

  $cfn->addResource('R1', 'AWS::IAM::User', Path => Cfn::DynamicValue->new(Value => sub { return 'Hello' });
  $cfn->path_to('Resources.R1.Properties.Path') # isa Cfn::DynamicValue
  $cfn->path_to('Resources.R1.Properties.Path')->as_hashref # eq 'Hello'

When C<$cfn->as_hashref> is invoked, all the dynamic values in the Cfn object will be 
called with the C<$cfn> instance as the first parameter to their subroutine

  $cfn->addResource('R1', 'AWS::IAM::User', Path => Cfn::DynamicValue->new(Value => sub {
    my $cfn = shift;
    return $cfn->ResourceCount + 41
  }));
  $cfn->as_hashref->{ Resources }->{ R1 }->{ Properties }->{ Path } # == 42

=head2 Cfn::Value::Function

All function statements derive from Cfn::Value::Function. 
The name of the function can be found in the C<Function> attribute
It's value can be found in the C<Value> attribute

=head2 Cfn::Value::Function::Ref

Object of this class represent a CloudFormation Ref. You can find the value 
of the reference in the C<Value> attribute. Note that the Value attribute contains
another C<Cfn::Value>. It derives from C<Cfn::Value::Function>

  $cfn->addResource('R1', 'AWS::IAM::User', Path => { Ref => 'AWS::Region' });
  $cfn->path_to('Resources.R1.Properties.Path') # isa Cfn::Value::Function::PseudoParameter

=head2 Cfn::Value::Function::PseudoParameter

This is a subclass of C<Cfn::Value::Function::Ref> used to hold what CloudFormation
calls PseudoParameters.

  $cfn->addResource('R1', 'AWS::IAM::User', Path => { Ref => 'AWS::Region' });
  $cfn->path_to('Resources.R1.Properties.Path') # isa Cfn::Value::Function::PseudoParam

=head2 Cfn::Value::Function::GetAtt

This class represents 'Fn::GetAtt' nodes in the object model. It's a subclass of C<Cfn::Value::Function>.

  $cfn->addResource('R1', 'AWS::IAM::User', Path => { 'Fn::GetAtt' => [ 'R1', 'InstanceId' ] });
  $cfn->path_to('Resources.R1.Properties.Path')             # isa Cfn::Value::Function::GetAtt
  $cfn->path_to('Resources.R1.Properties.Path')->LogicalId  # eq 'R1'
  $cfn->path_to('Resources.R1.Properties.Path')->Property   # eq 'InstanceId'

=head2 Cfn::Value::Array

This class represents Arrays in the object model. It's C<Value> property is an ArrayRef
of C<Cfn::Values> or C<Cfn::Resource::Properties>.

There is also a subtype called C<Cfn::Value::ArrayOfPrimitives> that restricts the values
in the array to C<Cfn::Value::Primitive> types.

=head2 Cfn::Value::Hash

This class represents JSON objects whose keys are not defined beforehand (arbitrary keys).
It's C<Value> property is a HashRef of C<Cfn::Value>s.

=head2 Cfn::Value::Primitive

This is a base class for any "simple" value (what the CloudFormation spec calls C<PrimitiveType>).
This classes C<Value> attribute has no type constraint, so it actually accepts anything. This class
is supposed to only be inherited from, specializing the C<Value> attribute to a specific type.

=head2 Cfn::Boolean

Used to store and validate CloudFormation C<Boolean> values. Has a C<stringy> attribute that controls if C<as_hashref>
returns a string boolean C<"true"> or C<"false"> or a literal C<true> or C<false>, since these two
boolean forms are accepted in CloudFormation.


=head2 Cfn::Integer

Used to store and validate CloudFormation C<Integer> values.

=head2 Cfn::Long

Used to store and validate CloudFormation C<Long> values.

=head2 Cfn::String

Used to store and validate CloudFormation C<String> values.

=head2 Cfn::Double

Used to store and validate CloudFormation C<Double> values.

=head2 Cfn::Timestamp

Used to store CloudFormation C<Timestamp> values. Only validates that it's a string.
  
=head2 Cfn::Value::TypedValue

Used as a base class for structured properties of CloudFormation resources. The subclasses
of TypedValue declare Moose attributes that are used to represent and validate that the
properties of a CloudFormation resource are well formed.

=head1 Cfn::Resource

Represents a CloudFormation Resource. All C<Cfn::Resource::*> objects (like L<Cfn::Resource::AWS::IAM::User>)
use C<Cfn::Resource> as a base class.

=head2 Attributes for Cfn::Resource objects

The attributes for Cfn::Resource objects map to the attributes of CloudFormation Resources.

    {
      "Type": "AWS::IAM::User",
      "Properties": { ... },
      "DependsOn": "R2"
      ...
    }

=head3 Type

Holds a string with the type of the resource.

=head3 Properties

Holds a C<Cfn::Value::Properties> subclass with the properties of the resource.

=head3 DeletionPolicy

Holds the DeletionPolicy. Validates that the DeletionPolicy is valid

=head3 DependsOn

Can hold either a single string or an arrayref of strings. This is because CloudFormation
supports C<DependsOn> in these two forms. Method C<DependsOnList> provides a uniform way
of accessing the DependsOn attribute.

=head3 Condition

Can hold a String identifying the Condition property of a resource

=head3 Metadata

Is a C<Cfn::Value::Hash> for the resources metadata

=head3 UpdatePolicy

Holds the UpdatePolicy. Validates that the UpdatePolicy is valid

=head3 CreationPolicy

HashRef with the CreationPolicy. Doesn't validate CreationPolicies.

=head2 Methods for Cfn::Resource objects

=head3 AttributeList

Returns an ArrayRef of attributes that can be recalled in CloudFormation via C<Fn::GetAtt>.

Can also be retrieved as a class method C<Cfn::Resource::...->AttributeList>

=head3 supported_regions

Returns an ArrayRef of the AWS regions where the resource can be provisioned.

Can also be retrieved as a class method C<Cfn::Resource::...->supported_regions>

=head3 DependsOnList

Returns a list of dependencies from the DependsOn attribute (it doesn't matter
if the DependsOn attribute is a String or an ArrayRef of Strings.

   my @deps = $cfn->Resource('R1')->DependsOnList;

=head3 hasAttribute($attribute)

Returns true if the specified attribute is in the C<AttributeList>. Note that some resources
(AWS::CloudFormation::CustomResource) can return true for values that are not in AttributeList

=head3 as_hashref

Like C<Cfn::Values>, as_hashref returns a HashRef representation of the object ready
for transforming to JSON.

=head1 Cfn::Resource::Properties

A base class for the objects that the C<Properties> attribute of C<Cfn::Resource>s hold.
Subclasses of C<Cfn::Resource::Properties> are used to validate and represent the properties
of resources inside the object model. See L<Cfn::Resource::Properties::AWS::IAM::User> for 
an example.

Each subclass of C<Cfn::Resource::Properties> has to have attributes to hold the values of 
the properties of the resource it represents.

=head1 Cfn::Parameter

Represents a Parameter in a CloudFormation document

  my $cfn = Cfn->new;
  $cfn->addParameter('P1', 'String', Default => 5);
  $cfn->Parameter('P1')->Default  # 5
  $cfn->Parameter('P1')->NoEcho   # undef

=head2 Cfn::Parameter Attributes

=head3 Type

A string with the type of parameter. Validates that it's a CloudFormation supported parameter type.

=head3 Default

Holds the default value for the parameter

=head3 NoEcho

Holds the NoEcho property of the parameter

=head3 AllowedValues

An ArrayRef of the allowed values of the parameter

=head3 AllowedPattern

A String holding the pattern that the value of this parameter can take

=head3 MaxLength, MinLength, MaxValue, MinValue

Values holding the MaxLength, MinLength, MaxValue, MinValue of the parameter

=head3 Description

A string description of the parameter

=head3 ConstraintDescription

A string description of the constraint of the parameter

=head1 Cfn::Mapping

This object represents the value of the C<Mappings> key in a CloudFormation
document. It has a C<Map> attribute to hold the Mappings in the CloudFormation
document.

=head1 Cfn::Output

Represents an output object in a CloudFormation document

=head2 Attributes for Cfn::Output objects

  "Outputs": {
    "Output1": {
      "Value": { "Ref": "Instance" }
    }
  }

=head3 Value

Holds the Value key of an output. Is a C<Cfn::Value>

=head3 Description

Holds a String with the descrption of the output

=head3 Condition

Holds a String with the condition of the output

=head3 Export

Holds a HashRef with the export definition of the object

=head2 Methods for Cfn::Output objects

=head3 as_hashref

Returns a HashRef representation of the output that is convertible to JSON

=head1 STABILITY

YAML support is recent, and due to the still evolving YAML::PP module, may break 
(altough the tests are there to detect that). This distribution will try to keep up 
as hard as it can with latest YAML::PP developments.

=head1 SEE ALSO

L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html>

This module kind of resembles troposphere (python): L<https://github.com/cloudtools/troposphere>.

=head1 CLI utils

This distribution includes a series of CLI utilities to help you with CloudFormation:

=head2 cfn_list_resources [STRING]

Lists all the resources supported by Cfn. If a string is specified, will filter the ones matching
the STRING.

=head2 cfn_region_matrix

Displays a table of what resource types are supported in each region

=head2 cfn_region_compatibility FILE

Takes a cloudformation template and calculates in what regions it will be deployable

=head2 cfn_resource_properties RESOURCE

Outputs information about a resource type: properties accessible via Fn::GetAtt, region availability
and it's whole property structure.

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 Contributions

Thanks to Sergi Pruneda, Miquel Ruiz, Luis Alberto Gimenez, Eleatzar Colomer, Oriol Soriano, 
Roi Vazquez for years of work on this module.

TINITA for helping make the YAML support possible. First for the YAML::PP module, which is the only
Perl module to support sufficiently modern YAML features, and also for helping me in the use of
YAML::PP.

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/cfn-perl>

Please report bugs to: L<https://github.com/pplu/cfn-perl/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
