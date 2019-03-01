package Cfn::Diff::Changes {
  use Moose;
  has path => (is => 'ro', isa => 'Str');
  has change => (is => 'ro', isa => 'Str');
  # to and from are left as rw because diff wants to
  # reassign these properties to the resolved version
  # when a DynamicValue is found
  has from => (is => 'rw');
  has to => (is => 'rw');
}

package Cfn::Diff::IncompatibleChange {
  use Moose;
  extends 'Cfn::Diff::Changes';
}

package Cfn::Diff::ResourcePropertyChange {
  use Moose;
  extends 'Cfn::Diff::Changes';
  has resource => (is => 'ro', isa => 'Cfn::Resource', required => 1);
  has property => (is => 'ro', isa => 'Str', required => 1);

  has mutability => (is => 'ro', isa => 'Str|Undef', lazy => 1, default => sub {
    my $self = shift;
    my $prop_meta = $self->resource->Properties->meta->find_attribute_by_name($self->property);
    return undef if (not $prop_meta->does('CfnMutability'));
    return $prop_meta->mutability;
  });
}

package Cfn::Diff {
  use Moose;

  has resolve_dynamicvalues => (
    is => 'ro',
    isa => 'Bool',
    default => 0
  );

  sub changes { 
    my $self = shift;
    return $self->_changes if (defined $self->_changes);
    $self->_changes([]);
    $self->_do_diff;
    return $self->_changes;
  }

  has _changes => (
    is => 'rw', 
    isa => 'ArrayRef[Cfn::Diff::Changes]', 
    traits => [ 'Array' ],
    handles => {
      new_addition => 'push',
      new_deletion => 'push',
      new_change   => 'push',
    },
  );

  has left => (is => 'ro', isa => 'Cfn', required => 1);
  has right => (is => 'ro', isa => 'Cfn', required => 1);

  sub _do_diff {
    my ($self) = @_;
    my $old = ($self->resolve_dynamicvalues) ? $self->left->resolve_dynamicvalues : $self->left;
    my $new = ($self->resolve_dynamicvalues) ? $self->right->resolve_dynamicvalues : $self->right;

    my %new_resources = map { ( $_ => 1 ) } $new->ResourceList;    
    my %old_resources = map { ( $_ => 1 ) } $old->ResourceList;    
    my %changed = ();
    foreach my $res (keys %new_resources) {
      if (exists $old_resources{ $res }) {

        if (my @changes = $self->_compare_resource($new->Resource($res), $old->Resource($res), $res)) {
          $self->new_change(@changes);
        }

        delete $new_resources{ $res };
        delete $old_resources{ $res };
      } else {
        $self->new_addition(Cfn::Diff::Changes->new(path => "Resources.$res", change => 'Resource Added', from => undef, to => $new->Resource($res)));
        delete $new_resources{ $res };
      } 
    }
    foreach my $res (keys %old_resources) {
      $self->new_deletion(Cfn::Diff::Changes->new(path => "Resources.$res", change => 'Resource Deleted', from => $old->Resource($res), to => undef));
    }
  }

  sub _compare_resource {
    my ($self, $new_res, $old_res, $logical_id) = @_;

    my $new_res_type = $new_res->Type;
    $new_res_type = 'AWS::CloudFormation::CustomResource' if ($new_res->isa('Cfn::Resource::AWS::CloudFormation::CustomResource'));
    my $old_res_type = $old_res->Type;
    $old_res_type = 'AWS::CloudFormation::CustomResource' if ($old_res->isa('Cfn::Resource::AWS::CloudFormation::CustomResource'));

    if ($new_res_type ne $old_res_type) {
      return Cfn::Diff::IncompatibleChange->new(
        path => "Resources.$logical_id", 
        change => 'Resource Type Changed', 
        from => $old_res->Type, 
        to => $new_res->Type,
      );
    }

    # This section diffs the resources properties
    my $new = $new_res->Properties;
    my $old = $old_res->Properties;

    if (not defined $new and not defined $old) {
      return ; # No changes, and don't go on trying to
               # diff the properties of unexisting objects
    } elsif (not defined $new or not defined $old) {
      my $message;
      $message = "Properties key deleted" if (not defined $new and defined $old);
      $message = "Properties key added" if (defined $new and not defined $old);

      return Cfn::Diff::Changes->new(
        path => "Resources.$logical_id",
        change => $message,
        from => $old,
        to => $new,
      );
    }

    # If we get here, the two objects have properties
    my @changes = ();
    foreach my $p ($new->meta->get_all_attributes) {
      my $meth = $p->name;
      my $new_val = $new->$meth;
      my $old_val = $old->$meth;

      next if (not defined $new_val and not defined $old_val);

      my $change_description;
      if      (    defined $old_val and not defined $new_val) {
        $change_description = 'Property Deleted';
      } elsif (not defined $old_val and     defined $new_val) {
        $change_description = 'Property Added';
      } elsif (    defined $old_val and     defined $new_val) {
        if (not $self->_properties_equal($new_val, $old_val, "$logical_id.$meth")) {
          $change_description = 'Property Changed';
        } else {
          next
        }
      } elsif (not defined $old_val and not defined $new_val) {
        next;
      }

      push @changes, Cfn::Diff::ResourcePropertyChange->new(
        path => "Resources.$logical_id.Properties.$meth",
        change => $change_description,
        from => $old_val,
        to => $new_val,
        resource => $new_res,
        property => $meth,
      );
    }
    return @changes;
  }

  use Scalar::Util;
  sub _properties_equal {
    my ($self, $new, $old) = @_;

    if (blessed($new)){
      if (blessed($old)){
        # See if old and new are of the same class
        return 0 if ($new->meta->name ne $old->meta->name);

        # Old and new are guaranteed to be the same type now, so just go on with new
        if ($new->isa('Cfn::DynamicValue')) {
          return 0;
        } elsif ($new->isa('Cfn::Value::Primitive')) {
          return ($new->Value eq $old->Value);
        } elsif ($new->isa('Cfn::Value::Function')) {
          return (($new->Function eq $old->Function) and $self->_properties_equal($new->Value, $old->Value));
        } elsif ($new->isa('Cfn::Value')) {
          return $self->_properties_equal($new->as_hashref, $old->as_hashref);
        } else {
          die "Don't know how to compare $new";
        }
      } else {
        return 0;
      }
    } else {
      if (blessed($old)) { 
        return 0;
      } else {
        return 0 if (ref($old) ne ref($new));
        if (not ref($new)){
          return ($new eq $old);
        } elsif (ref($new) eq 'ARRAY') {
          return 0 if (@$new != @$old);
          for (my $i = 0; $i < @$new; $i++) {
            return 0 if (not $self->_properties_equal($new->[$i], $old->[$i]));
          }
          return 1;
        } elsif (ref($new) eq 'HASH') {
          return 0 if ((keys %$new) != (keys %$old));
          foreach my $key (keys %$new) {
            return 0 if (not $self->_properties_equal($new->{ $key }, $old->{ $key }));
          }
          return 1;
        } else {
          die "Don't know how to non-blessed compare " . ref($new);
        }
      }
    }
  }
}

1;
