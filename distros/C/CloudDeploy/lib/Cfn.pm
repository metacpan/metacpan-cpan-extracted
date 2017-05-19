use Moose::Util::TypeConstraints;

subtype 'Cfn::Resource::DeletionPolicy',
as 'Str',
where { $_ eq 'Delete' or $_ eq 'Retain' or $_ eq 'Snapshot' },
message { "$_ is an invalid DeletionPolicy" };

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
  my @keys = keys %$arg;
  my $first_key = $keys[0];
  if (@keys == 1 and (substr($first_key,0,4) eq 'Fn::' or $first_key eq 'Ref' or $first_key eq 'Condition')){
    if ($first_key eq 'Fn::GetAtt') { 
      Cfn::Value::Function::GetAtt->new(Function => $first_key, Value => $arg->{ $first_key });
    } elsif ($keys[0] eq 'Ref'){
      Cfn::Value::Function::Ref->new( Function => $first_key, Value => $arg->{ $first_key });
    } elsif ($keys[0] eq 'Condition'){
      Cfn::Value::Function::Condition->new( Function => $first_key, Value => $arg->{ $first_key });
    } else {
      Cfn::Value::Function->new(Function => $first_key, Value => $arg->{ $first_key });
    }
  } else {
    Cfn::Value::Hash->new(Value => {
        map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($arg->{$_}) } @keys
      });
  }
}

coerce 'Cfn::Value',
from 'Int|Str',  via { Cfn::Value::Primitive->new( Value => $_ ) },
from 'HashRef',  via (\&coerce_hash),
from 'ArrayRef', via (\&coerce_array);

coerce 'Cfn::Value::Array',
from 'HashRef',  via (\&coerce_hash),
from 'ArrayRef', via (\&coerce_array);

coerce 'Cfn::Value::ArrayOfPrimitives',
from 'HashRef',  via (\&coerce_hash),
from 'ArrayRef', via (\&coerce_array);


coerce 'Cfn::Value::Hash',
from 'HashRef',  via (\&coerce_hash);


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
  return Cfn::Mapping->new(%$_);
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
  my $type = delete $_->{Type};
  die "Can't coerce HashRef into a Cfn::Resource if it doesn't have a Type key" if (not defined $type);
  $type = "AWS::CloudFormation::CustomResource" if ($type =~ m/^Custom\:\:/);

  Cfn->load_resource_module($type);
  # Properties is needed, although there are no properties
  $_->{Properties} = {} if (not exists $_->{Properties});
  return "Cfn::Resource::$type"->new(
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

package Cfn::Value {
  use Moose;
  has Value => (isa => 'Cfn::Value', is => 'rw', required => 1, coerce => 1);

  sub as_hashref { shift->Value->as_hashref(@_) }
}

package Cfn::Value::Function {
  use Moose;
  extends 'Cfn::Value';
  has 'Function' => (isa => 'Str', is => 'rw', required => 1);
  # inherits Value property as a Cfn::Value

  sub as_hashref { 
    my $self = shift;
    my $key = $self->Function; 
    return { $key => $self->Value->as_hashref(@_) } 
  }
}

package Cfn::Value::Function::Condition {
  use Moose;
  extends 'Cfn::Value::Function';
  #has '+Value' => (isa => 'Cfn::Value::Primitive', coerce => 1);

  sub Condition {
    shift->Value->Value;
  }
}

package Cfn::Value::Function::Ref {
  use Moose;
  extends 'Cfn::Value::Function';
  #has '+Value' => (isa => 'Cfn::Value::Primitive', coerce => 1);

  sub LogicalId {
    shift->Value->Value;
  }
}

package Cfn::Value::Function::GetAtt {
  use Moose;
  extends 'Cfn::Value::Function';
  has '+Value' => (isa => 'Cfn::Value::ArrayOfPrimitives', coerce => 1);

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
  has '+Value' => (
    isa => 'ArrayRef[Cfn::Value]', 
    traits => ['Array'],
    handles => {
      'Count' => 'count',
    }
  );

  sub as_hashref {
    my $self = shift;
    my @args = @_;
    return [ map { $_->as_hashref(@args)  } @{ $self->Value } ]
  };
}

package Cfn::Value::Hash {
  use Moose;
  extends 'Cfn::Value';
  has '+Value' => (isa => 'HashRef[Cfn::Value]');
  override as_hashref => sub {
    my $self = shift;
    my @args = @_;
    return { map { $_ => $self->Value->{$_}->as_hashref(@args) } keys %{ $self->Value } };
  };
}

package Cfn::Value::Primitive {
  use Moose;
  extends 'Cfn::Value';
  has '+Value' => (isa => 'Int|Str');
  override as_hashref => sub {
    my $self = shift;
    return $self->Value;
  }
}

package Cfn::Resource {
  use Moose;
  # CCfnX::Dependencies is not production ready
  with 'CCfnX::Dependencies';
  has Type => (isa => 'Str', is => 'rw', required => 1, default => sub {
      my $type = shift->meta->name;
      $type =~ s/^Cfn\:\:Resource\:\://;
      return $type;
    });
  has Properties => (isa => 'Cfn::Resource::Properties', is => 'rw', required => 1);
  has DeletionPolicy => (isa => 'Cfn::Resource::DeletionPolicy', is => 'rw');
  has DependsOn => (isa => 'ArrayRef[Str]|Str', is => 'rw');
  has Condition => (isa => 'Str', is => 'rw');

  sub DependsOnList {
    my $self = shift;
    return () if (not defined $self->DependsOn);
    return @{ $self->DependsOn } if (ref($self->DependsOn) eq 'ARRAY');
    return $self->DependsOn;
  }

  has Metadata => (isa => 'Cfn::Value::Hash', is => 'rw', coerce => 1);
  #TODO: validate this http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html
  has UpdatePolicy => (isa => 'HashRef', is => 'rw');

  sub as_hashref {
    my $self = shift;
    my @args = @_;
    return {
      (map { $_ => $self->$_->as_hashref(@args) }
        grep { defined $self->$_ } qw/Properties Metadata/),
      (map { $_ => $self->$_ }
        grep { defined $self->$_ } qw/Type DeletionPolicy DependsOn UpdatePolicy Condition/),
    }
  }
}

package Cfn::Resource::Properties {
  use Moose;
  sub as_hashref {
    my $self = shift;
    my @args = @_;

    #return {
    my $ret = {};
    #map { (defined $self->$_) ? ($_ => $self->$_->as_hashref(@args)) : () } $self->meta->get_all_attributes
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
    #}
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

package Cfn::Output {
  use Moose;
  has Value => (isa => 'Cfn::Value', is => 'rw', required => 1, coerce => 1);
  has Condition => (isa => 'Str', is => 'rw');
  sub as_hashref {
    my $self = shift;
    return { Value => $self->Value->as_hashref,
      (defined $self->Condition) ? (Condition => $self->Condition) : ()
    }
  }
}

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
];

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

package Cfn {
  use Moose;
  use Moose::Util;
  has AWSTemplateFormatVersion => (isa => 'Str', is => 'ro', default => '2010-09-09' );
  has Description => (isa => 'Str', is => 'rw', required => 1, default => '' );
  has Transform => (isa => 'Str', is => 'rw');
  has Parameters => (
    is => 'rw',
    isa => 'Cfn::ParameterHash', 
    coerce => 1, 
    default => sub { {} },
    traits => [ 'Hash' ],
    handles => {
      ParameterCount => 'count',
    },
  );
  has Mappings => (
    is => 'rw',
    isa => 'Cfn::MappingHash', 
    coerce => 1,
    traits => [ 'Hash' ],
    handles => {
      Mapping => 'get',
      MappingCount => 'count',
    },
    default => sub { {} }
  );
  has Conditions => (
    is => 'rw',
    isa => 'Cfn::ConditionHash',
    traits  => [ 'Hash' ],
    coerce => 1,
    handles => {
      Condition => 'get',
      ConditionList => 'keys',
      ConditionCount => 'count',
    },
    default => sub { {} }
  );
  has Resources => (
    is      => 'rw',
    isa     => 'Cfn::ResourceHash',
    coerce => 1,
    traits  => [ 'Hash' ],
    handles => {
      Resource => 'get',
      ResourceList => 'keys',
      ResourceCount => 'count',
    },
    default => sub { {} }
  );
  has Outputs => (
    is      => 'rw',
    isa     => 'Cfn::OutputHash',
    coerce  => 1,
    traits  => [ 'Hash' ],
    handles => {
      Output => 'get',
      OutputCount => 'count',
    },
    default => sub { {} },
  );
  has Metadata => (
    is      => 'rw',
    isa     => 'Cfn::MetadataHash',
    coerce  => 1,
    traits  => [ 'Hash' ],
    handles => {
      MetadataItem => 'get',
      MetadataList => 'keys',
      MetadataCount => 'count',
    },
    default => sub { {} },
  );
  use Module::Runtime qw//;
  sub load_resource_module {
    my (undef, $type) = @_;
    my $cfn_resource_class = "Cfn::Resource::$type";
    my $retval = Module::Runtime::require_module($cfn_resource_class);
    die "Couldn't load $cfn_resource_class" if (not $retval);
    return $cfn_resource_class;
  }

  #method addParameter (Str $name, Cfn::Parameter|Str $type, %rest) {
  sub addParameter {
    my ($self, $name, $type, %rest) = @_;
    die "A parameter named $name already exists" if ($self->Parameters->{ $name });
    if (ref $type) {
      return $self->Parameters->{ $name } = $type;
    } else {
      return $self->Parameters->{ $name } = Cfn::Parameter->new(Type => $type, %rest);
    }
  }

  #method addMapping (Str $name, $mapping) {
  sub addMapping {
    my ($self, $name, $mapping) = @_;
    die "A mapping named $name already exists" if ($self->Mappings->{ $name });
    if (ref $mapping eq 'HASH') {
      return $self->Mappings->{ $name } = Cfn::Mapping->new(Map => $mapping);
    } else {
      return $self->Mappings->{ $name } = $mapping;
    }   
  }

  #method addOutput (Str $name, $output, @rest) {
  sub addOutput {
    my ($self, $name, $output, @rest) = @_;
    die "An output named $name already exists" if ($self->Outputs->{ $name });
    return $self->Outputs->{ $name } = Cfn::Output->new( Value => $output, @rest );
  }

  sub addCondition {
    my ($self, $name, $value) = @_;
    die "A condition named $name already exists" if ($self->Conditions->{ $name });
    return $self->Conditions->{ $name } = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce($value);
  }

  sub addResource {
    my ($self, $name, $type, @rest) = @_;
    die "A resource named $name already exists" if ($self->Resources->{ $name });
    if (not ref $type){
      return $self->Resources->{ $name } = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource')->coerce({
          Type => $type,
          Properties => { @rest }
        });
    } else {
      return $self->Resources->{ $name } = $type;
    }
  }

  #method addMetadata (Str $name, %args) {
  sub addMetadata {
    my ($self, $name, %args) = @_;
    die "A resource named $name must already exist" if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->Metadata({ %args });
  }
  #method addResourceMetadata (Str $name, %args) {
  sub addResourceMetadata {
    my ($self, $name, %args) = @_;
    die "A resource named $name must already exist" if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->Metadata({ %args });
  }
  #method addDependsOn (Str $name, @args) {
  sub addDependsOn {
    my ($self, $name, @args) = @_;
    die "A resource named $name must already exist" if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->DependsOn( [ @args ] );
  }
  #method addDeletionPolicy (Str $name, Str $policy) {
  sub addDeletionPolicy {
    my ($self, $name, $policy) = @_;
    die "A resource named $name must already exist" if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->DeletionPolicy( $policy );
  }
  #method addUpdatePolicy (Str $name, Str $policy) {
  sub addUpdatePolicy {
    my ($self, $name, $policy) = @_;
    die "A resource named $name must already exist" if (not defined $self->Resources->{ $name });
    $self->Resources->{ $name }->UpdatePolicy( $policy );
  }

  sub from_hashref {
    my ($class, $hashref) = @_;
    return $class->new(%$hashref);
  }

  sub as_hashref {
    my $self = shift;
    return {
      AWSTemplateFormatVersion => $self->AWSTemplateFormatVersion,
      Description => $self->Description,
      (defined $self->Transform) ? (Transform => $self->Transform) : (),
      Resources => { map { ($_ => $self->Resource($_)->as_hashref($self)) } $self->ResourceList },
      (keys %{$self->Mappings} > 0) ? ( Mappings => { map { ($_ => $self->Mappings->{ $_ }->as_hashref) } keys %{ $self->Mappings } } ) : (),
      Parameters => { map { ($_ => $self->Parameters->{ $_ }->as_hashref) } keys %{ $self->Parameters } },
      Outputs => { map { ($_ => $self->Outputs->{ $_ }->as_hashref($self)) } keys %{ $self->Outputs } },
      Conditions => { map { ($_ => $self->Condition($_)->as_hashref($self)) } $self->ConditionList },
      Metadata => { map { ($_ => $self->Metadata->{ $_ }->as_hashref($self)) } $self->MetadataList },
    }
  }

  has json => (is => 'ro', lazy => 1, default => sub {
      require JSON;
      return JSON->new->pretty->canonical
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

}

1;
