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

package Cfn::Diff {
  use Moose;
  extends 'Cfn';

  has changes => (
    is => 'rw', 
    isa => 'ArrayRef[Cfn::Diff::Changes]', 
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
      new_addition => 'push',
      new_deletion => 'push',
      new_change   => 'push',
    },
  );

  has left => (is => 'ro', isa => 'Cfn', required => 1);
  has right => (is => 'ro', isa => 'Cfn', required => 1);

  sub diff {
    my ($self) = @_;
    my $old = $self->left;
    my $new = $self->right;

    my %new_resources = map { ( $_ => 1 ) } $new->ResourceList;    
    my %old_resources = map { ( $_ => 1 ) } $old->ResourceList;    
    my %changed = ();
    foreach my $res (keys %new_resources) {
      if (exists $old_resources{ $res }) {
        if (my @changes = $self->compare_resource($new->Resource($res)->Properties, $old->Resource($res)->Properties, $res)) {
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

  sub compare_resource {
    my ($self, $new, $old, $res) = @_;
    my @changes = ();
    foreach my $p ($new->meta->get_all_attributes) {
      my $meth = $p->name;
      my $new_val = $new->$meth;
      my $old_val = $old->$meth;

      next if (not defined $new_val and not defined $old_val);

      if (not defined $new_val) {
        push @changes, Cfn::Diff::Changes->new(path => "Resources.$res.Properties.$meth", change => 'Property Deleted', from => $old_val, to => undef);
        next;
      }
      if (not defined $old_val) {
        push @changes, Cfn::Diff::Changes->new(path => "Resources.$res.Properties.$meth", change => 'Property Added', from => undef, to => $new_val);
        next;
      }
      if (not $self->properties_equal($new_val, $old_val, "$res.$meth")) {
        push @changes, Cfn::Diff::Changes->new(path => "Resources.$res.Properties.$meth", change => 'Property Changed', from => $old_val, to => $new_val);
        next;
      }
    }
    return @changes;
  }

  use Scalar::Util;
  sub properties_equal {
    my ($self, $new, $old) = @_;

    if (blessed($new)){
      if (blessed($old)){
        # See if old and new are of the same class
        return 0 if ($new->meta->name ne $old->meta->name);

        # Old and new are guaranteed to be the same type now, so just go on with new
        if ($new->isa('Cfn::Value::Primitive')) {
          return ($new->Value eq $old->Value);
        } elsif ($new->isa('Cfn::Value::Function')) {
          return (($new->Function eq $old->Function) and $self->properties_equal($new->Value, $old->Value));
        } elsif ($new->isa('Cfn::Value')) {
          return $self->properties_equal($new->Value, $old->Value);
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
            return 0 if (not $self->properties_equal($new->[$i], $old->[$i]));
          }
          return 1;
        } elsif (ref($new) eq 'HASH') {
          return 0 if ((keys %$new) != (keys %$old));
          foreach my $key (keys %$new) {
            return 0 if (not $self->properties_equal($new->{ $key }, $old->{ $key }));
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
