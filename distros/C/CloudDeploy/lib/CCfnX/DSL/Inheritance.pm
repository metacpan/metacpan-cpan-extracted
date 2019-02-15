package CCfnX::DSL::Inheritance {
  use Moose;
  use Hash::Merge qw/merge _merge_hashes/;

  Hash::Merge::specify_behavior({

    # Left side always has precedence in the case of scalars
    # Avoid merging different types
    'SCALAR' => {
      'SCALAR' => sub { $_[0] },
      'ARRAY'  => sub { die "Can't merge a scalar with an an array. Use replace behavior instead" },
      'HASH'   => sub { die "Can't merge a scalar with a hash. Use replace behavior instead" },
    },
    'ARRAY' => {
      'SCALAR' => sub { die "Can't merge an array with a scalar"  },
      'ARRAY'  => sub { [ @{ $_[0] }, @{ $_[1] } ] },
      'HASH'   => sub { die "Can't merge an array with a hash" },
    },
    'HASH' => {
      'SCALAR' => sub { die "Can't merge a hash with a scalar" },
      'ARRAY'  => sub { die "Can't merge a hash with an array" },
      'HASH'   => sub { _merge_hashes( $_[0], $_[1] ) },
    },
  });

  Moose::Exporter->setup_import_methods(
    as_is => [ qw/resolve_resource_inheritance_dsl/ ]
  );

  sub resolve_resource_inheritance_dsl {
    # receives a hash with keys 'resource', 'properties', 'extra'
    my ($params) = @_;

    my $meta = $params->{meta};
    my ($inherited, $attr_name) = _is_inherited($params->{name});

    if (not $inherited) {
      die "Redeclared resource/output/condition/parameter/mapping $params->{name}"
        if ($meta->find_attribute_by_name($params->{name}));

      return sub {
        return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource')->coerce({
          Type => $params->{resource},
          Properties => $params->{properties},
          %{$params->{extra}},
        });
      }
    }

    else {

      my $attr = $meta->find_attribute_by_name($attr_name);
      die "Couldn't find any resource with name $attr_name"
        if (not defined $attr);
      die "Attribute $attr_name exist but is not of type " . $params->{attr_family}
        if (not $attr->does($params->{attr_family}));

      # Execute the default attribute value coderef to get the superclass resource
      my $object = &{$attr->default};

      $object = _apply_inheritance_dsl($object, $params->{extra});
      $object->Properties(_apply_inheritance_dsl($object->Properties, $params->{properties}));

      return sub { return $object};
    }

  };

  # This method applies DSL inheritance for each key defined in the given passed objects
  sub _apply_inheritance_dsl {
    my ($inherited_object, $hashref_with_dsl) = @_;

    foreach my $attr_with_dsl (keys %{$hashref_with_dsl}) {

      my ($behavior, $attr_name) = _get_inheritance_dsl_behavior($attr_with_dsl);

      if ($behavior eq "REPLACE") {
          my $attr_new_value = $hashref_with_dsl->{$attr_with_dsl};
          $inherited_object->$attr_name($attr_new_value);
      }

      elsif ($behavior eq "MERGE") {

        my $attr_inherited_value = $inherited_object->$attr_name;
        my $attr_type_constraint = $inherited_object->meta->find_attribute_by_name($attr_name)->type_constraint;
        my $attr_new_value = Moose::Util::TypeConstraints::find_type_constraint($attr_type_constraint)->coerce( $hashref_with_dsl->{$attr_with_dsl} );

        # Merge the new value with the old one
        $attr_inherited_value->Value(merge($attr_new_value->Value,$attr_inherited_value->Value));
      }

      elsif ($behavior eq "DELETE") {
          delete $inherited_object->{$attr_name};
      }
    }

    return $inherited_object;
  };

  sub _is_inherited {
    my $name = shift;
    if ( $name =~ /\+(.*)/ ) {
      return (1, substr($name,1));
    } else {
      return (0, $name);
    }
  };

  sub _get_inheritance_dsl_behavior {
    my $name = shift;
    die "Unrecognized resource property inheritance DSL: $name. Allowed values are: '+', '-', '~'"
      if ( $name !~ /\+(.*)|\~(.*)|-(.*)/ );

    return ("REPLACE", substr($name,1)) if ( $name =~ /\+(.*)/ );
    return ("DELETE", substr($name,1)) if ( $name =~ /\-(.*)/ );
    return ("MERGE", substr($name,1)) if ( $name =~ /\~(.*)/ );
  }

};

1;
