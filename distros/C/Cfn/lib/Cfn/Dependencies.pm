package Cfn::Dependencies {
  use Moose::Role;

  sub resolve_references_to_logicalid_with {
    my ($self, $logical_id, $object) = @_;
    $self->Properties->resolve_references_to_logicalid_with($logical_id, $object);
  }

  sub resolve_parameters {
    # Scan all resources resolving parameters to their value
  }

  sub resolve_functions {
    # Execute functions
  }

  sub resolve_references {
    # 
  }

  sub get_deps_from_object {
    my ($object, $deps) = @_;

    return $deps if (not defined $object);
    
    if ($object->isa('Cfn::Value::Array')) {
      get_deps_from_object($_, $deps) for (@{ $object->Value });
    } elsif ($object->isa('Cfn::Value::Function::Ref') or $object->isa('Cfn::Value::Function::GetAtt')) {
      $deps->{ $object->LogicalId } = 1;
    } elsif ($object->isa('Cfn::Value::Function')) {
      get_deps_from_object($object->Value, $deps);
    } elsif ($object->isa('Cfn::Value::Hash')) {
      get_deps_from_object($object->Value->{ $_ }, $deps) for (keys %{ $object->Value });
    } elsif ($object->isa('Cfn::Resource')) {
      # Deps in attributes
      if (defined $object->Properties) {
        get_deps_from_object($object->Properties->$_, $deps) for map { $_->name } ($object->Properties->meta->get_all_attributes);
      }
      # Add explicit DependsOn
      $deps->{ $_ } = 1 for ($object->DependsOnList);
    }
    return $deps;
  }

  sub dependencies {
    my $self = shift;
    return [ keys %{ get_deps_from_object($self, { }) } ];
  }

  sub undeclared_dependencies {
    my $self = shift;
    # register all deps in 
    my @errors = grep { not $self->Resource($_) and not $self->Parameter($_) } @{ $self->dependencies };
    return @errors;
  }

  # Calculates the dependency tree between resources
  # Dies upon circular dependencies or not declared resource  
  sub dependency_tree {
    my($self, $deps, $dtree) = @_;
    my @resources = $self->ResourceList;
    
    if (!$dtree) {
        $dtree = Tree->new('root');
        $deps  = \@resources;
    }
    
    foreach my $dep (@$deps) {
        my $curr = Tree->new($dep);
        $dtree->add_child($curr);
        
        # Detect circular dependencies
        if ($dtree->depth > scalar @resources) {
            my $dep_resources = {};
            while (!$dtree->is_root) {                # Approximate resources involved
                $dep_resources->{$dtree->value} = 1;  # in the circular dependency
                $dtree = $dtree->parent;
            }
            die "Could not create dependency tree due to circular dependencies around resources: ". join(',', keys %$dep_resources)."\n";
        }
        die "Could not find resource $dep declared as a dependency of ".$dtree->value."\n"  if(!$self->Resources->{$dep});
        $curr = $self->dependency_tree( $self->Resources->{$dep}->DependsOn, $curr );
    }
    return $dtree;
  }
  
  # Returns ArrayRef of resource names in order of creation to respect dependencies
  sub resource_creation_order {
    my $self = shift;
    my $dep_tree = $self->dependency_tree;
    
    my @nodes    = $dep_tree->traverse( $dep_tree->POST_ORDER );
    pop @nodes;   # ditch 'root' node
    
    my $created_resources = {};
    my @create_order;
    #my @create_order = map { $_->value } @nodes;
    
    # Avoid returning duplicates using aux hash?
    #   `·->Must! per distingir del cas de recursos amb noms duplicats      
    foreach (@nodes) {   
        push @create_order, $_->value  unless($created_resources->{$_->value}); # if not created already
        $created_resources->{$_->value} = 1;
    }
    return \@create_order;
  }
}

1;
