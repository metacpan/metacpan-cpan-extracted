package Class::AutoDB::RegistryDiff;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use Class::AutoClass;
use Class::AutoDB::RegistryVersion;
use Class::AutoDB::Collection;
use Class::AutoDB::CollectionDiff;
@ISA = qw(Class::AutoClass);

BEGIN {
  @AUTO_ATTRIBUTES=qw(baseline other
		      baseline_only new_collections
		      equivalent_diffs sub_diffs super_diffs expanded_diffs inconsistent_diffs
		     );
  @OTHER_ATTRIBUTES=qw();
  %SYNONYMS=();
  Class::AutoClass::declare(__PACKAGE__,\@AUTO_ATTRIBUTES,\%SYNONYMS);
}

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my($baseline,$other)=$self->get(qw(baseline other));

  my($baseline_only,$new,$equivalent,$sub,$super,$expanded,$inconsistent);
  my $baseline_collections=$baseline->collections;
  for my $collection (@$baseline_collections) {
    my $name=$collection->name;
    my $other_collection=$other->collection($name);
    if (defined $other_collection) {
      my $diff=new Class::AutoDB::CollectionDiff(-baseline=>$collection,
						 -other=>$other_collection);
      push(@$equivalent,$diff) if $diff->is_equivalent;
      push(@$sub,$diff) if $diff->is_sub;
      push(@$super,$diff) if $diff->is_super;
      push(@$expanded,$diff) if $diff->is_expanded;
      push(@$inconsistent,$diff) if $diff->is_inconsistent;
    } else { 
      push(@$baseline_only,$collection);
    }
  }
  my $other_collections=$other->collections;
  for my $collection (@$other_collections) {
    my $name=$collection->name;
    push(@$new,$collection) unless defined $baseline->collection($name);
  }
  $self->baseline_only($baseline_only || []);
  $self->new_collections($new || []);
  $self->equivalent_diffs($equivalent || []);
  $self->sub_diffs($sub || []);
  $self->super_diffs($super || []);
  $self->expanded_diffs($expanded || []);
  $self->inconsistent_diffs($inconsistent || []);
}

#sub baseline_only -- attribute
#sub new_collections -- attribute
sub equivalent_collections {$_[0]->_collections('equivalent_diffs');}
sub sub_collections {$_[0]->_collections('sub_diffs');}
sub super_collections {$_[0]->_collections('super_diffs');}
sub expanded_collections {$_[0]->_collections('expanded_diffs');}
sub inconsistent_collections {$_[0]->_collections('inconsistent_diffs');}
sub _collections {
  my($self,$what_diffs)=@_;
  my $result; 
  @$result=map {$_->other} @{$_[0]->$what_diffs};
  $result;
}
sub is_consistent {@{$_[0]->inconsistent_diffs}==0;}
sub is_inconsistent {@{$_[0]->inconsistent_diffs}>0;}
sub is_equivalent {
  my($self)=@_;
  my $baseline_collections=$self->baseline->collections || [];
  my $other_collections=$self->other->collections || [];
  @{$self->equivalent_diffs}==@$baseline_collections &&
    @$baseline_collections==@$other_collections;
}
sub is_different {!$_[0]->is_equivalent;}
sub is_sub {
  my($self)=@_;
  my $other_collections=$self->other->collections || [];
  $self->is_consistent && @{$self->sub_diffs}==@$other_collections;
}
sub is_super {
  my($self)=@_;
  my $baseline_collections=$self->baseline->collections || [];
  $self->is_consistent && @{$self->super_diffs}==@$baseline_collections;
}
sub has_new {@{$_[0]->new_collections}>0;}
sub has_expanded {@{$_[0]->expanded_diffs}>0;}

1;
