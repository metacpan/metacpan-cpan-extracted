package CCfn { 
  use Moose;
  extends 'Cfn';

  use Cfn;
  use CCfnX::DynamicValue;

  has stash => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
  );

  # Holds the mappings from logical output name, to the output name that will be sent and retrieved from cloudformation
  # This is done to support characters in the output names that cloudformation doesn't
  has output_mappings => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { {} },
  );
  has debug => (is => 'ro', default => sub { return $ENV{ CLOUDDEPLOY_DEBUG } ? 1 : 0 });

  # Helper to safely add things to stash
  sub add_to_stash {
    my ($self, $name, $value) = @_;
    die "An element is already in the stash with name $name" if (exists $self->stash->{$name});
    $self->stash->{ $name } = $value;
  }

  # Small helper to map a Moose class (parameters have a type) to a CloudFormation type
  sub _moose_to_cfn_class {
    return {  
      Str => 'String',
      Int => 'Number',
      Num => 'Number',
    }->{ $_[0] } || 'String';
  }

  # When the object is instanced, we want any of the attributes declared in the class to be created
  # That means that attributes with Resource, Output, Condition or Output roles are "attached" to the object
  # This is done to make the newly created object represent all that the user has declared "in the class" when
  # they call ->new
  # All these attributes are normally created with CCfnX::Shortcuts, but can really be created by hand (not recommended)
  sub BUILD {
    my $self = shift;
    my $class_meta = $self->meta;
    my @attrs = $class_meta->get_all_attributes;
    foreach my $att (@attrs) {
      my $name = $att->name;
      if ($att->does('CCfnX::Meta::Attribute::Trait::Resource')) {
        $self->addResource($name, $self->$name);
      } elsif ($att->does('CCfnX::Meta::Attribute::Trait::Output')){
        $self->addOutput($name, $self->$name);
      } elsif ($att->does('CCfnX::Meta::Attribute::Trait::Condition')){
        $self->addCondition($name, $self->$name);
      } elsif ($att->does('CCfnX::Meta::Attribute::Trait::Mapping')){
        $self->addMapping($name, $self->$name);
      } elsif ($att->does('CCfnX::Meta::Attribute::Trait::Metadata')){
        $self->addMetadata($name, $self->$name);
      } elsif ($att->does('CCfnX::Meta::Attribute::Trait::Transform')){
        $self->addTransform($name, $self->$name);
      }
    }

    my $params_meta = $self->params->meta;
    @attrs = $params_meta->get_all_attributes;
    foreach my $param (@attrs) {
      if ($param->does('CCfnX::Meta::Attribute::Trait::StackParameter')) {
        my $type = $param->type_constraint->name;
        $self->addParameter($param->name, _moose_to_cfn_class($type));
      }
    }

  }

  sub get_stackversion_from_metadata {
    my $self = shift;
    $self->Metadata('StackVersion');
  }

  before as_hashref => sub {
    my $self = shift;
    # This triggers any actions that the class
    # wants to do while building the cloudformation
    $self->build();
  };

  around addOutput => sub { 
    my ($orig, $self, $name, $output, @rest) = @_;
    my $new_name = $name;
    $new_name =~ s/\W//g;
    if (defined $self->Output($new_name)) {
      die "The output name clashed with an existing output name. Be aware that outputs are stripped of all non-alphanumeric chars before being declared";
    }
    if ($new_name ne $name) {
      $self->output_mappings->{ $new_name } = $name;
    }
    $self->$orig($new_name, $output, @rest);
  };

  use Data::Graph::Util qw//;

  sub _creation_order {
    my ($self) = @_;

    my $graph = {};
    foreach my $resource ($self->ResourceList) {
      $graph->{ $resource } = $self->Resource($resource)->dependencies;
    }

    my @result = Data::Graph::Util::toposort($graph, [ sort $self->ResourceList ]);

    return reverse @result;
  }

  sub build {}

  use Module::Runtime qw//;
  sub get_deployer {
    my ($self, $params, @roles) = @_;
    Module::Runtime::require_module($_) for ('CCfnX::Deployment', @roles);
    my $dep = CCfnX::Deployment->new_with_roles({ %$params, origin => $self }, @roles);
    return $dep;
  }
}

package CCfnX::Meta::Attribute::Trait::RefValue {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('RefValue');
}

package CCfnX::Meta::Attribute::Trait::StackParameter {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('StackParameter');
}

package CCfnX::Meta::Attribute::Trait::Resource {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('Resource');
}

package CCfnX::Meta::Attribute::Trait::Metadata {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('Metadata');
}

package CCfnX::Meta::Attribute::Trait::Condition {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('Condition');
}

package CCfnX::Meta::Attribute::Trait::Output {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('Output');
}

package CCfnX::Meta::Attribute::Trait::Mapping {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('Mapping');
}

package CCfnX::Meta::Attribute::Trait::Transform {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('Transform');
}

package CCfnX::Meta::Attribute::Trait::PostOutput {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('PostOutput');
}

package CCfnX::Meta::Attribute::Trait::Attached {
  use Moose::Role;
  Moose::Util::meta_attribute_alias('Attached');
}

package CCfnX::Meta::Attribute::Trait::Attachable {
  use Moose::Role;
  use CCfnX::Deployment;
  Moose::Util::meta_attribute_alias('Attachable');
  has type => (is => 'ro', isa => 'Str', required => 1);
  has generates_params => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  sub get_info {
    my ($self, $name, $key) = @_;
    die "Please specify a name for Attachment " . $self->name if (not defined $name);
    my $dep = CCfnX::Deployment->new_with_roles({ name => $name }, 'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentDeployment');
    $dep->get_from_mongo;

    my $output;
    eval { $output = $dep->output($key) };
    
    return $output;
  }
}

1;
