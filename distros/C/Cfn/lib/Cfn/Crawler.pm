package Cfn::Crawler::Path;
  use Moose;

  has path => (is => 'ro', isa => 'Str', required => 1);
  has element => (is => 'ro', required => 1);

package Cfn::Crawler;
  use Moose;

  has resolve_dynamicvalues => (is => 'ro', isa => 'Bool', default => 0);

  has cfn => (is => 'ro', isa => 'Cfn', required => 1);

  has _resolved_cfn => (is => 'ro', isa => 'Cfn', lazy => 1, default => sub {
    my $self = shift;
    if ($self->resolve_dynamicvalues) {
      return $self->cfn->resolve_dynamicvalues;
    } else {
      return $self->cfn;
    }
  });

  has criteria => (is => 'ro', isa => 'CodeRef', required => 1);

  has _all => (
    is => 'ro',
    lazy => 1,
    builder => '_scan_all',
    isa => 'ArrayRef',
    traits => ['Array'],
    handles => {
      all => 'elements'
    },
  );
  for my $property (qw/resources outputs parameters
                       metadata mappings conditions/){
    has "_$property" => (
      is => 'ro',
      lazy => 1,
      builder => "_scan_$property",
      isa => 'ArrayRef',
      traits => [ 'Array' ],
      handles => {
        $property => 'elements',
      }
    );
  }

  sub _match {
    my ($self, $path, $element) = @_;
    if ($self->criteria->($element)) {
      return Cfn::Crawler::Path->new(
        path => $path,
        element => $element,
      );
    } else {
      return ();
    }
  }

  sub _scan_all {
    my $self = shift;

    my @results;

    push @results, $self->resources;
    push @results, $self->outputs;
    push @results, $self->parameters;
    push @results, $self->mappings;
    push @results, $self->metadata;
    push @results, $self->conditions;

    return \@results;
  }

  sub _scan_conditions {
    my $self = shift;
    my @results;

    foreach my $c_name (sort $self->_resolved_cfn->ConditionList) {
      my $path = "Conditions.$c_name";
      my $condition = $self->_resolved_cfn->Condition($c_name);

      push @results, $self->_match($path, $condition);

      #TODO: Can't crawl into conditions, because they are not proper
      #      objects yet
      #foreach my $cond_key (keys %$condition) {
      #  push @results, $self->_crawl_values("$path\.$cond_key", $condition->{ $cond_key });
      #}
    }

    return \@results;
  }

  sub _scan_metadata {
    my $self = shift;
    my @results;

    foreach my $md_name (sort $self->_resolved_cfn->MetadataList) {
      my $path = "Metadata.$md_name";
      my $metadata = $self->_resolved_cfn->MetadataItem($md_name);

      push @results, $self->_match($path, $metadata);
    }

    return \@results;
  }

  sub _scan_mappings {
    my $self = shift;
    my @results;

    foreach my $m_name (sort $self->_resolved_cfn->MappingList) {
      my $path = "Mappings.$m_name";
      my $mapping = $self->_resolved_cfn->Mapping($m_name);

      push @results, $self->_match($path, $mapping);
    }

    return \@results;
  }

  sub _scan_parameters {
    my $self = shift;
    my @results;

    foreach my $p_name (sort $self->_resolved_cfn->ParameterList) {
      my $path = "Parameters.$p_name";
      my $parameter = $self->_resolved_cfn->Parameter($p_name);

      push @results, $self->_match($path, $parameter);
    }

    return \@results;
  }

  sub _scan_outputs {
    my $self = shift;
    my @results;

    foreach my $o_name (sort $self->_resolved_cfn->OutputList) {
      my $path = "Outputs.$o_name";
      my $output = $self->_resolved_cfn->Output($o_name);

      push @results, $self->_match($path, $output);

      push @results, $self->_crawl_values("$path\.Value", $output->Value);
    }

    return \@results;
  }

  sub _scan_resources {
    my $self = shift;
    my @results;

    foreach my $r_name (sort $self->_resolved_cfn->ResourceList) {
      my $path = "Resources.$r_name";
      my $resource = $self->_resolved_cfn->Resource($r_name);

      push @results, $self->_match($path, $resource);

      next if (not defined $resource->Properties);

      foreach my $prop ($resource->Properties->meta->get_all_attributes) {
        my $prop_name = $prop->name;
        my $prop_value = $resource->Property($prop_name);
        
        push @results, $self->_crawl_values("$path\.Properties\.$prop_name", $prop_value);
      }
    }

    return \@results;
  }

  #
  # since Cfn::Values are recursive (can contain other Cfn::Values)
  # this guy will recurse over them, and for the ones matching the 
  # criteria, will give you a path to them
  #
  sub _crawl_values {
    my ($self, $path, $value) = @_;
    
    return if (not blessed $value);
    die "Found something that isn't a Cfn::Value" if (not $value->isa('Cfn::Value'));

    my @results;

    push @results, $self->_match($path, $value);

    if ($value->isa('Cfn::Value::Array')) {
      my $index = 0;
      foreach my $element (@{ $value->Value }) {
        push @results, $self->_crawl_values("$path\.$index", $element);
        $index++;
      }
    } elsif ($value->isa('Cfn::Value::Function')) {
      push @results, $self->_crawl_values("$path\." . $value->Function, $value->Value);
    } elsif ($value->isa('Cfn::Value::Hash')) {
      my $index;
      foreach my $key (sort keys %{ $value->Value }){
        push @results, $self->_crawl_values("$path\.$key", $value->Value->{ $key });
      }
    } elsif ($value->isa('Cfn::Value::Primitive')) {
      # A primitives value is not traversable
    } elsif ($value->isa('Cfn::Value::TypedValue')) {
      foreach my $property ($value->meta->get_all_attributes) {
        my $prop_name = $property->name;
        my $prop_value = $value->$prop_name;
        push @results, $self->_crawl_values("$path\.$prop_name", $prop_value);
      }
    } elsif ($value->isa('Cfn::DynamicValue')) {
      # A DynamicValue is not traversable
    } else {
      die "Unknown $value at $path";
    }

    return @results;
  }

1;
